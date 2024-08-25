# == Schema Information
#
# Table name: record_trigrams
#
#  call_number     :
#  origin_names    :
#  parents         :
#  rank            :
#  record_trigrams :
#  summary         :
#  title           :
#  record_id       :
#
class RecordTrigram < ApplicationRecord
  belongs_to :archive_file, foreign_key: :record_id

  scope :search,
        ->(query) do
          return none if query.blank?

          where(record_trigrams: "title: \"#{query}\"")
            .or(where(record_trigrams: "summary: \"#{query}\""))
            .or(where(record_trigrams: "parents: \"#{query}\""))
            .or(where(record_trigrams: "origin_names: \"#{query}\""))
            .or(where(record_trigrams: "call_number: \"#{query}\""))
            .order(:call_number)
        end

  scope :lookup_by_call_number,
        ->(call_number) do
          where(record_trigrams: "call_number: \"#{query}\"").order(
            :call_number
          )
        end
end
