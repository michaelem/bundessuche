class AddArchiveNodeToRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :records, :archive_node_id, :integer
    add_index :records, :archive_node_id
  end
end
