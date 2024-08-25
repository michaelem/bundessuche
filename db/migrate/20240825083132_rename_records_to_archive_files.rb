class RenameRecordsToArchiveFiles < ActiveRecord::Migration[7.1]
  def change
    rename_table :records, :archive_files
  end
end
