class AddUniqueIndexToRecord < ActiveRecord::Migration[7.1]
  def change
    add_index :records, :source_id, unique: true
  end
end
