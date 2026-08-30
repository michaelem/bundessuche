# A query typed into the search box. A "*" in it stands for any run of
# characters, so "Chaussee*123" finds a Chaussee with a 123 somewhere after it.
# Everything else is literal text, and a query without a "*" keeps meaning
# exactly the substring it has always meant.
#
# Matching takes two steps, because the trigram index cannot answer a wildcard
# query on its own. The literal pieces between the wildcards are looked up in
# the index, which narrows millions of rows down to a few candidates, and a GLOB
# pattern then checks that those pieces really do appear in one column and in
# the right order. The index only proposes; the pattern decides.
class SearchQuery
  WILDCARD = "*"

  # The trigram index cannot answer anything shorter than a trigram: a phrase of
  # one or two characters silently matches no rows at all. Pieces that short are
  # left out of the index lookup and checked by the GLOB pattern instead.
  MIN_INDEXABLE_LENGTH = 3

  # The characters GLOB reads as syntax, which a character class turns back into
  # plain text.
  GLOB_SPECIAL = ["*", "?", "["].freeze

  # The literal pieces of the query, in the order they have to appear. Repeated
  # and trailing wildcards add nothing, so the empty pieces around them are
  # dropped: "Chaussee**123*" asks for the same two pieces as "Chaussee*123".
  attr_reader :segments

  def initialize(text)
    @text = text.to_s
    @segments = @text.split(WILDCARD).reject(&:empty?)
  end

  # Whether the index can narrow this query down at all. Without one piece long
  # enough to look up, answering it would mean reading every row, so a query
  # this short finds nothing rather than costing a full scan.
  def indexable?
    segments.any? { |segment| segment.length >= MIN_INDEXABLE_LENGTH }
  end

  # The FTS5 expression for the pieces long enough to look up. They are ANDed
  # rather than joined into one phrase because FTS5 has no way to say "and then
  # later on", which is exactly what the wildcard between them means. That makes
  # the index deliberately too generous: it also proposes rows carrying the
  # pieces in the wrong order, or spread across two columns, and the GLOB
  # pattern is what throws those out again.
  def fts_match
    indexable_segments.map { |segment| %("#{segment.gsub('"', '""')}") }.join(" AND ")
  end

  # The pattern the candidates are held against. Wrapped in wildcards at both
  # ends because every search here matches anywhere inside the text.
  def glob_pattern
    WILDCARD + segments.map { |segment| escape_glob(segment) }.join(WILDCARD) + WILDCARD
  end

  private

  def indexable_segments
    segments.select { |segment| segment.length >= MIN_INDEXABLE_LENGTH }
  end

  def escape_glob(segment)
    segment.each_char.map { |char| escape_glob_character(char) }.join
  end

  # GLOB is case sensitive and has no escape character, but a character class
  # covers both jobs: "[aA]" matches either case of a letter and "[*]" matches a
  # literal asterisk. Spelling the two cases out is also what makes the match
  # case insensitive beyond ASCII, where LIKE would give up: "münchen" finds
  # "MÜNCHEN".
  def escape_glob_character(char)
    return "[#{char}]" if GLOB_SPECIAL.include?(char)

    lower = char.downcase
    upper = char.upcase
    # "ß".upcase is "SS". A character whose other case is not a single character
    # does not fit in a class, so it stands only for itself.
    return char if lower == upper || lower.length > 1 || upper.length > 1

    "[#{lower}#{upper}]"
  end
end
