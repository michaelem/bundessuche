class RecordsTrigram < ApplicationRecord
  self.table_name = "records_trigram"
  belongs_to :record
end
