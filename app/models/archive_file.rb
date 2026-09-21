# == Schema Information
#
# Table name: archive_files
#
#  id                  :integer          not null, primary key
#  call_number         :string
#  language_code       :string
#  link                :text
#  link_variant        :integer
#  source_date_end     :date
#  source_date_start   :date
#  source_date_text    :string
#  source_uuid         :binary
#  summary             :string
#  title               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  archive_location_id :integer
#  archive_node_id     :integer
#  source_id           :text
#
# Indexes
#
#  index_archive_files_on_archive_node_id   (archive_node_id)
#  index_archive_files_on_call_number       (call_number)
#  index_archive_files_on_source_date_text  (source_date_text)
#  index_archive_files_on_source_uuid       (source_uuid) UNIQUE
#
class ArchiveFile < ApplicationRecord
  # SQL for the effective source date range of an archive file: the parsed date
  # text if it could be parsed, otherwise the dates the importer read from the
  # XML. Both expect parsed_source_dates to be joined in.
  EFFECTIVE_SOURCE_DATE_START =
    'COALESCE(parsed_source_dates.start_date, archive_files.source_date_start)'
  EFFECTIVE_SOURCE_DATE_END = <<~SQL.squish
    CASE WHEN parsed_source_dates.start_date IS NOT NULL
      THEN COALESCE(parsed_source_dates.end_date, parsed_source_dates.start_date)
      ELSE COALESCE(archive_files.source_date_end, archive_files.source_date_start)
    END
  SQL

  # Raised when the upstream data stops looking the way source_uuid and
  # link_variant assume it looks. Failing the import is deliberate: the
  # alternative is silently storing an identifier or a link that cannot be
  # rebuilt.
  class UnexpectedSourceFormat < StandardError; end

  # Every archive file is identified upstream as "DE-1958_<uuid>" and linked
  # through one of two Invenio URL templates, always with the same uuid. Keeping
  # sixteen raw bytes and a template number instead of the two strings costs
  # about 17 bytes a row rather than 130.
  #
  # source_id and link are generated columns that rebuild the original text in
  # SQL, so everything that reads them, including find_by(source_id:), carries on
  # working and neither string is stored anywhere.
  SOURCE_ID_PREFIX = 'DE-1958_'
  UUID_FORMAT = '\\h{8}-\\h{4}-\\h{4}-\\h{4}-\\h{12}'
  SOURCE_ID_PATTERN = /\A#{Regexp.escape(SOURCE_ID_PREFIX)}(#{UUID_FORMAT})\z/
  LINK_TEMPLATES = [
    'https://invenio.bundesarchiv.de/invenio/direktlink/%s/',
    'https://invenio.bundesarchiv.de/basys2-invenio/direktlink/%s/'
  ].freeze
  LINK_PATTERNS =
    LINK_TEMPLATES
    .map do |template|
      prefix, suffix = template.split('%s')
      /\A#{Regexp.escape(prefix)}(#{UUID_FORMAT})#{Regexp.escape(suffix)}\z/
    end
      .freeze

  # Matching runs over three trigram tables at once: the files themselves, the
  # archive nodes above them and their origins. A file inherits a match from any
  # node on its ancestor chain, which is what the per-file copy of the ancestor
  # path used to do before the index was split up.
  #
  # Each of the three lookups is a pair: the trigram index proposes candidates
  # and the GLOB pattern decides which of them really match. The index cannot do
  # it alone because a wildcard query goes in as its pieces ANDed together,
  # which also proposes rows carrying those pieces out of order or spread over
  # two columns. See SearchQuery.
  MATCHING_IDS = <<~SQL.squish
    WITH RECURSIVE matching_nodes(id) AS (
      SELECT n.id FROM archive_nodes n
      WHERE n.id IN (SELECT rowid FROM archive_node_trigrams WHERE archive_node_trigrams MATCH :match)
        AND n.name GLOB :glob
      UNION
      SELECT n.id FROM archive_nodes n JOIN matching_nodes m ON n.parent_node_id = m.id
    )
    SELECT f.id FROM archive_files f
    WHERE f.id IN (SELECT rowid FROM archive_file_trigrams WHERE archive_file_trigrams MATCH :match)
      AND (f.title GLOB :glob OR f.summary GLOB :glob OR f.call_number GLOB :glob)
    UNION
    SELECT f.id FROM archive_files f JOIN matching_nodes m ON f.archive_node_id = m.id
    UNION
    SELECT o.archive_file_id FROM originations o
    WHERE o.origin_id IN (
      SELECT g.id FROM origins g
      WHERE g.id IN (SELECT rowid FROM origin_trigrams WHERE origin_trigrams MATCH :match)
        AND g.name GLOB :glob
    )
  SQL

  belongs_to :archive_node
  belongs_to :archive_location, optional: true

  has_many :originations, inverse_of: :archive_file
  has_many :origins, through: :originations

  belongs_to :parsed_source_date,
             foreign_key: :source_date_text,
             primary_key: :source_text,
             optional: true,
             inverse_of: :archive_files

  after_create :insert_trigram
  after_update :update_trigram
  after_destroy :delete_trigram

  scope :search,
        lambda { |query|
          search_query = SearchQuery.new(query)
          return none unless search_query.indexable?

          where(
            "archive_files.id IN (#{MATCHING_IDS})",
            match: search_query.fts_match,
            glob: search_query.glob_pattern
          ).order(:call_number)
        }

  # Keeps the archive files whose effective source date range overlaps the given
  # range. Both boundaries are optional; without either one nothing is filtered
  # out. Files without any date at all never match a filtered search.
  scope :source_dated_between,
        lambda { |from, to|
          next all if from.blank? && to.blank?

          scope =
            left_outer_joins(:parsed_source_date).where(
              "#{EFFECTIVE_SOURCE_DATE_START} IS NOT NULL"
            )

          scope = scope.where("#{EFFECTIVE_SOURCE_DATE_END} >= ?", from) if from.present?

          scope = scope.where("#{EFFECTIVE_SOURCE_DATE_START} <= ?", to) if to.present?

          scope
        }

  # The sixteen raw bytes behind "DE-1958_<uuid>".
  def self.pack_source_id(source_id)
    match = SOURCE_ID_PATTERN.match(source_id.to_s)
    if match.nil?
      raise UnexpectedSourceFormat,
            "archive file id #{source_id.inspect} is not #{SOURCE_ID_PREFIX}<uuid>"
    end

    [match[1].delete('-')].pack('H*')
  end

  # Which template a link uses, or nil when the file has no link at all.
  def self.link_variant_for(link)
    return nil if link.blank?

    variant = LINK_PATTERNS.index { |pattern| pattern.match?(link) }
    raise UnexpectedSourceFormat, "archive file link #{link.inspect} matches no known template" if variant.nil?

    variant
  end

  def self.update_cached_all_count
    count = all.count
    CachedCount.find_or_create_by(model: name, scope: :all).update(
      count: count
    )
  end

  def self.cached_all_count
    CachedCount.find_by(model: name, scope: :all)&.count
  end

  def self.reindex(show_progress = false)
    if show_progress
      start = Time.now

      progress_bar = ProgressBar.create(
        title: 'Reindexing',
        total: ArchiveFile.count,
        format: '%t %p%% %a %e |%B|',
        output: $stdout
      )
    end

    connection.execute('DELETE FROM archive_file_trigrams')

    find_in_batches do |group|
      attrs_list = group.map(&:trigram_attributes)
      columns = attrs_list.first.keys.join(', ')
      values = attrs_list.map do |attrs|
        "(#{attrs.values.map { |v| connection.quote(v) }.join(', ')})"
      end.join(', ')
      connection.execute("INSERT INTO archive_file_trigrams(#{columns}) VALUES #{values}")
      group.size.times { progress_bar.increment } if show_progress
    end

    ArchiveNode.reindex
    Origin.reindex

    return unless show_progress

    puts "Reindexing took #{Time.now - start} seconds"
  end

  # Fills in the ancestor chains for a whole page of files with one query, so
  # that rendering them does not walk the tree once per row.
  def self.preload_parents(archive_files)
    archive_files = archive_files.to_a
    chains = ArchiveNode.ancestor_chains(archive_files.map(&:archive_node_id))

    archive_files.each do |archive_file|
      archive_file.preloaded_parents =
        chains.fetch(archive_file.archive_node_id, [])
    end

    archive_files
  end

  attr_writer :preloaded_parents

  # The archive nodes above this file, root first and including the node holding
  # it. This used to be a JSON column repeating the names on every row, which
  # cost 1.4 GB for something archive_nodes already describes.
  def parents
    @preloaded_parents ||=
      ArchiveNode.ancestor_chains(archive_node_id).fetch(archive_node_id, [])
  end

  def source_uuid_text
    return nil if source_uuid.blank?

    hex = source_uuid.unpack1('H*')
    [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join('-')
  end

  # SQLite fills these in for saved rows. A record that has not been written yet
  # has no generated value to read, so both fall back to building the string
  # here from the same pieces.
  def source_id
    return self[:source_id] if self[:source_id].present?

    uuid = source_uuid_text
    uuid && "#{SOURCE_ID_PREFIX}#{uuid}"
  end

  def source_id=(value)
    self.source_uuid = value.nil? ? nil : self.class.pack_source_id(value)
  end

  def link
    return self[:link] if self[:link].present?
    return nil if link_variant.nil? || source_uuid_text.nil?

    format(LINK_TEMPLATES.fetch(link_variant), source_uuid_text)
  end

  def link=(value)
    self.link_variant = self.class.link_variant_for(value)
  end

  # The call number reduced to letters, digits and underscores. Call numbers
  # carry spaces and slashes, which neither a file name nor a BibTeX citation
  # key can hold.
  def folded_call_number
    call_number.to_s.gsub(/[^A-Za-z0-9]+/, '_').delete_prefix('_').delete_suffix('_')
  end

  def source_dates
    return [source_date_start.to_s] if source_date_end.blank? || source_date_start == source_date_end

    [source_date_start.to_s, source_date_end.to_s]
  end

  # The dates behind the source date text: the parsed range when the text could
  # be read, otherwise the range the importer took from the XML. The Ruby
  # counterpart of EFFECTIVE_SOURCE_DATE_START and EFFECTIVE_SOURCE_DATE_END,
  # which filter searches by the same rule.
  def effective_source_dates
    if parsed_source_date&.start_date.present?
      start_date = parsed_source_date.start_date
      end_date = parsed_source_date.end_date
    else
      start_date = source_date_start
      end_date = source_date_end
    end

    return [] if start_date.blank?

    [start_date, end_date || start_date]
  end

  def source_date_years
    return [] if source_date_start.blank? && source_date_end.blank?

    return [source_date_start.year.to_s] if source_date_end.blank? || source_date_start.year == source_date_end.year

    [source_date_start.year.to_s, source_date_end.year.to_s]
  end

  # The trigram table is contentless and keyed by the archive file's own id, so
  # rowid stands in for the archive_file_id column it used to carry.
  def trigram_attributes
    { rowid: id, title: title, summary: summary, call_number: call_number }
  end

  def insert_trigram
    trigram_attrs = trigram_attributes

    values = trigram_attrs.values.map { |v| ArchiveFile.connection.quote(v) }
    sql_insert = <<~SQL.strip
      INSERT INTO archive_file_trigrams(#{trigram_attrs.keys.join(', ')}) VALUES(#{values.join(', ')});
    SQL
    self.class.connection.execute(sql_insert)
  end

  def delete_trigram
    delete_statement =
      "DELETE FROM archive_file_trigrams WHERE rowid = #{attributes['id']}"
    self.class.connection.execute(delete_statement)
  end

  def update_trigram
    # Not very efficient, but fine for now as this should basically never happen
    delete_trigram
    insert_trigram
  end
end
