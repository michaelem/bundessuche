class RecordTrigram < ApplicationRecord
  belongs_to :record

  scope :search,
        ->(query) do
          return none if query.blank?

          where(record_trigrams: "title: #{query}")
            .or(where(record_trigrams: "summary: #{query}"))
            .or(where(record_trigrams: "parents: #{query}"))
            .or(where(record_trigrams: "origin_names: #{query}"))
            .order(:call_number)
        end
end
