class CreateRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :records do |t|
      t.string :title
      t.string :call_number
      t.string :source_date
      t.string :source_id

      t.timestamps
    end
  end
end
