# frozen_string_literal: true

class RenameRecordTrigramsToArchiveFileTrigrams < ActiveRecord::Migration[7.1]
  def change
    rename_table :record_trigrams, :archive_file_trigrams
  end
end
