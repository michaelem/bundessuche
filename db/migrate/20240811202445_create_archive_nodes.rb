class CreateArchiveNodes < ActiveRecord::Migration[7.1]
  def change
    create_table :archive_nodes do |t|
      t.string :name
      t.integer :parent_node_id
      t.string :source_id

      t.timestamps

      t.index :source_id, unique: true
      t.index :parent_node_id
    end
  end
end
