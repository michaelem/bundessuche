class CreateOrigins < ActiveRecord::Migration[7.1]
  def change
    create_table :origins do |t|
      t.integer :label, default: 0
      t.string :name

      t.index %i[label name], unique: true
      t.index :name, using: :gin, opclass: :gin_trgm_ops

      t.timestamps
    end

    create_table :originations, id: false do |t|
      t.belongs_to :record
      t.belongs_to :origin

      t.index %i[record_id origin_id], unique: true
    end
  end
end
