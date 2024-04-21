class SeperateRecordsIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :records, :title, using: :gin, opclass: :gin_trgm_ops
    add_index :records, :summary, using: :gin, opclass: :gin_trgm_ops
  end
end
