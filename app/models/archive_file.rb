# == Schema Information
#
# Table name: archive_files
#
#  id                  :integer          not null, primary key
#  call_number         :string
#  language_code       :string
#  link                :string
#  source_date_end     :date
#  source_date_start   :date
#  source_date_text    :string
#  summary             :string
#  title               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  archive_location_id :integer
#  archive_node_id     :integer
#  source_id           :string
#
# Indexes
#
#  index_archive_files_on_archive_node_id   (archive_node_id)
#  index_archive_files_on_call_number       (call_number)
#  index_archive_files_on_source_date_text  (source_date_text)
#  index_archive_files_on_source_id         (source_id) UNIQUE
#
class ArchiveFile < ApplicationRecord
  # SQL for the effective source date range of an archive file: the parsed date
  # text if it could be parsed, otherwise the dates the importer read from the
  # XML. Both expect parsed_source_dates to be joined in.
  EFFECTIVE_SOURCE_DATE_START =
    "COALESCE(parsed_source_dates.start_date, archive_files.source_date_start)"
  EFFECTIVE_SOURCE_DATE_END = <<~SQL.squish
    CASE WHEN parsed_source_dates.start_date IS NOT NULL
      THEN COALESCE(parsed_source_dates.end_date, parsed_source_dates.start_date)
      ELSE COALESCE(archive_files.source_date_end, archive_files.source_date_start)
    END
  SQL

  # Matching runs over three trigram tables at once: the files themselves, the
  # archive nodes above them and their origins. A file inherits a match from any
  # node on its ancestor chain, which is what the per-file copy of the ancestor
  # path used to do before the index was split up.
  MATCHING_IDS = <<~SQL.squish
    WITH RECURSIVE matching_nodes(id) AS (
      SELECT rowid FROM archive_node_trigrams WHERE archive_node_trigrams MATCH :match
      UNION
      SELECT n.id FROM archive_nodes n JOIN matching_nodes m ON n.parent_node_id = m.id
    )
    SELECT rowid FROM archive_file_trigrams WHERE archive_file_trigrams MATCH :match
    UNION
    SELECT f.id FROM archive_files f JOIN matching_nodes m ON f.archive_node_id = m.id
    UNION
    SELECT o.archive_file_id FROM originations o
    WHERE o.origin_id IN (SELECT rowid FROM origin_trigrams WHERE origin_trigrams MATCH :match)
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
        ->(query) do
          return none if query.blank?

          where("archive_files.id IN (#{MATCHING_IDS})", match: fts_phrase(query))
            .order(:call_number)
        end

  # Keeps the archive files whose effective source date range overlaps the given
  # range. Both boundaries are optional; without either one nothing is filtered
  # out. Files without any date at all never match a filtered search.
  scope :source_dated_between,
        ->(from, to) do
          next all if from.blank? && to.blank?

          scope =
            left_outer_joins(:parsed_source_date).where(
              "#{EFFECTIVE_SOURCE_DATE_START} IS NOT NULL"
            )

          if from.present?
            scope = scope.where("#{EFFECTIVE_SOURCE_DATE_END} >= ?", from)
          end

          if to.present?
            scope = scope.where("#{EFFECTIVE_SOURCE_DATE_START} <= ?", to)
          end

          scope
        end

  # FTS5 reads a bare query as its own query syntax, so the whole thing goes in
  # as a single quoted phrase with any quote inside it escaped.
  def self.fts_phrase(query)
    %("#{query.to_s.gsub('"', '""')}")
  end

  def self.update_cached_all_count
    count = self.all.count
    CachedCount.find_or_create_by(model: self.name, scope: :all).update(
      count: count
    )
  end

  def self.cached_all_count
    CachedCount.find_by(model: self.name, scope: :all)&.count
  end

  def self.reindex(show_progress=false)
    if show_progress
      start = Time.now

      progress_bar = ProgressBar.create(
        title: "Reindexing",
        total: ArchiveFile.count,
        format: "%t %p%% %a %e |%B|",
        output: $stdout
      )
    end

    connection.execute("DELETE FROM archive_file_trigrams")

    self.find_in_batches do |group|
      attrs_list = group.map(&:trigram_attributes)
      columns = attrs_list.first.keys.join(", ")
      values = attrs_list.map { |attrs|
        "(#{attrs.values.map { |v| connection.quote(v) }.join(", ")})"
      }.join(", ")
      connection.execute("INSERT INTO archive_file_trigrams(#{columns}) VALUES #{values}")
      group.size.times { progress_bar.increment } if show_progress
    end

    ArchiveNode.reindex
    Origin.reindex

    if show_progress
      puts "Reindexing took #{Time.now - start} seconds"
    end
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

  def source_dates
    if source_date_end.blank? || source_date_start == source_date_end
      return [source_date_start.to_s]
    end

    [source_date_start.to_s, source_date_end.to_s]
  end

  def source_date_years
    return [] if source_date_start.blank? && source_date_end.blank?

    if source_date_end.blank? || source_date_start.year == source_date_end.year
      return [source_date_start.year.to_s]
    end

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
      INSERT INTO archive_file_trigrams(#{trigram_attrs.keys.join(", ")}) VALUES(#{values.join(", ")});
    SQL
    self.class.connection.execute(sql_insert)
  end

  def delete_trigram
    delete_statement =
      "DELETE FROM archive_file_trigrams WHERE rowid = #{attributes["id"]}"
    self.class.connection.execute(delete_statement)
  end

  def update_trigram
    # Not very efficient, but fine for now as this should basically never happen
    delete_trigram
    insert_trigram
  end
end
