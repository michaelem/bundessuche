class AddNormalisedSourceDateToRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :records, :source_date_start, :date
    add_column :records, :source_date_end, :date
    rename_column :records, :source_date, :source_date_text
  end
end
