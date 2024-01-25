class AddFieldsToRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :records, :link, :string
    add_column :records, :location, :string
    add_column :records, :language_code, :string
    add_column :records, :summary, :string

    remove_index :records, name: "records_search"
    add_index :records,
              "to_tsvector('german', title || ' ' || call_number || ' ' || summary)",
              using: :gin,
              name: "records_search"
  end
end
