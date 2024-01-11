class AddIndexToRecordCallNumber < ActiveRecord::Migration[7.1]
  def change
    add_index :records, :call_number
  end
end
