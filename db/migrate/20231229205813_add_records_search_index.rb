class AddRecordsSearchIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :records,
              "to_tsvector('german', title || ' ' || call_number)",
              using: :gin,
              name: "records_search"
  end
end
