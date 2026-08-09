# == Schema Information
#
# Table name: archive_file_trigrams
#
#  archive_file_trigrams :
#  call_number           :
#  origin_names          :
#  parents               :
#  rank                  :
#  summary               :
#  title                 :
#  archive_file_id       :
#  archive_node_id       :
#
class ArchiveFileTrigram < ApplicationRecord
  belongs_to :archive_file

  scope :search,
        ->(query) do
          return none if query.blank?

          where(archive_file_trigrams: "\"#{query}\"").order(:call_number)
        end

  # Keeps the archive files whose effective source date range overlaps the given
  # range. Both boundaries are optional; without either one nothing is filtered
  # out. Files without any date at all never match a filtered search.
  scope :source_dated_between,
        ->(from, to) do
          next all if from.blank? && to.blank?

          scope =
            left_outer_joins(archive_file: :parsed_source_date).where(
              "#{ArchiveFile::EFFECTIVE_SOURCE_DATE_START} IS NOT NULL"
            )

          if from.present?
            scope =
              scope.where("#{ArchiveFile::EFFECTIVE_SOURCE_DATE_END} >= ?", from)
          end

          if to.present?
            scope =
              scope.where("#{ArchiveFile::EFFECTIVE_SOURCE_DATE_START} <= ?", to)
          end

          scope
        end

  scope :lookup_by_call_number,
        ->(call_number) do
          where(archive_file_trigrams: "call_number: \"#{query}\"").order(
            :call_number
          )
        end
end
