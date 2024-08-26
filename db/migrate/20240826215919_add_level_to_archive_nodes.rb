class AddLevelToArchiveNodes < ActiveRecord::Migration[7.1]
  def change
    add_column :archive_nodes, :level, :string
  end
end
