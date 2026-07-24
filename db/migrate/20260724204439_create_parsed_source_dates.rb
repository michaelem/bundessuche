class CreateParsedSourceDates < ActiveRecord::Migration[8.1]
  def change
    create_table :parsed_source_dates do |t|
      t.string :source_text, null: false
      t.date :start_date
      t.date :end_date
      t.float :confidence
      t.string :model_name
      t.text :raw_response

      t.timestamps
    end

    add_index :parsed_source_dates, :source_text, unique: true
    add_index :archive_files, :source_date_text
  end
end
