class CreateCachedCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :cached_counts do |t|
      t.string :model
      t.string :scope
      t.bigint :count

      t.timestamps

      t.index %i[model scope], unique: true
    end
  end
end
