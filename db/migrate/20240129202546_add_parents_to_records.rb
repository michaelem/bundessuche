class AddParentsToRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :records, :parents, :string, array: true, default: []
  end
end
