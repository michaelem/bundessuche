class AddTrgmIndexToRecords < ActiveRecord::Migration[7.1]
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    add_index :records,
              %i[title summary],
              using: :gin,
              opclass: {
                title: :gin_trgm_ops,
                summary: :gin_trgm_ops
              }
  end
end
