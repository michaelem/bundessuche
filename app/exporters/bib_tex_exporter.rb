class BibTexExporter
  # BibTeX writes months as one of twelve macros rather than as a number.
  MONTHS = %w[jan feb mar apr may jun jul aug sep oct nov dec].freeze

  def initialize(archive_file)
    @archive_file = archive_file
  end

  def export
    lines = fields.map { |name, value| "  #{name} = {#{indent(value)}}," }
    lines << "  month = #{MONTHS.fetch(month - 1)}," if month

    "@unpublished{#{citation_key},\n#{lines.join("\n")}\n}\n"
  end

  private

  # Blank fields are dropped rather than written out empty: a reader importing
  # the entry should see nothing where the archive knows nothing.
  def fields
    {
      url: escape(@archive_file.link),
      title: escape(@archive_file.title),
      abstract: escape(@archive_file.summary),
      language: escape(@archive_file.language_code),
      author: author,
      year: @archive_file.source_date_start&.year,
      note: issued_note
    }.compact_blank
  end

  # The author is the holding institution, not a person. The inner braces keep
  # BibTeX from reading the name as "family, given" and reordering its parts,
  # which turns "Müller & Co." into "Co., Müller &".
  def author
    name = escape(@archive_file.parents.first&.name)
    "{#{name}}" if name.present?
  end

  # Call numbers carry spaces and slashes, neither of which a citation key can
  # hold, so they are folded the same way the citation file names fold them.
  # Every key is prefixed, since a bare "DC_20_797" says nothing about where the
  # entry came from once it sits in a shared bibliography.
  def citation_key
    key = @archive_file.folded_call_number
    key = @archive_file.source_id.to_s.tr('_', '-') if key.blank?

    "BArch_#{key}"
  end

  def issued_note
    years = @archive_file.source_date_years.join('/')
    "issued:#{years}" if years.present?
  end

  def month
    @archive_file.source_date_start&.month
  end

  # Summaries come out of the archive carrying their own line breaks, which
  # would otherwise continue at column zero and leave the entry looking like it
  # had ended. The breaks stay, pulled in under the field they belong to;
  # BibTeX pays no attention to whitespace between the braces.
  def indent(value)
    value.to_s.gsub(/\r\n?|\n/, "\n    ")
  end

  # Field values are wrapped in braces, so a brace or a backslash out of the
  # archive text would tear the entry apart at the point a reader parses it.
  # Neither carries meaning in a German archival title, so both are dropped.
  def escape(value)
    value.to_s.strip.gsub(/[\\{}]/, '')
  end
end
