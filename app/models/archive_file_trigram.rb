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
#
class ArchiveFileTrigram < ApplicationRecord
  belongs_to :archive_file

  scope :search,
        ->(query) do
          return none if query.blank?

          where(archive_file_trigrams: "title: \"#{query}\"")
            .or(where(archive_file_trigrams: "summary: \"#{query}\""))
            .or(where(archive_file_trigrams: "parents: \"#{query}\""))
            .or(where(archive_file_trigrams: "origin_names: \"#{query}\""))
            .or(where(archive_file_trigrams: "call_number: \"#{query}\""))
            .order(:call_number)
        end

  scope :lookup_by_call_number,
        ->(call_number) do
          where(archive_file_trigrams: "call_number: \"#{query}\"").order(
            :call_number
          )
        end
end
