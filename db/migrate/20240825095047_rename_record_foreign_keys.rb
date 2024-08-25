class RenameRecordForeignKeys < ActiveRecord::Migration[7.1]
  def change
    rename_column :archive_file_trigrams, :record_id, :archive_file_id
    rename_column :originations, :record_id, :archive_file_id
  end
end
