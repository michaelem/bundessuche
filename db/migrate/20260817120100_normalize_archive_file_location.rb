class NormalizeArchiveFileLocation < ActiveRecord::Migration[8.1]
  # The importer writes one of nine archive locations into every row as a
  # string, which costs about 60 MB for nine distinct values. A lookup table
  # keeps the data and drops the repetition.
  #
  # language_code stays as it is. Every row currently says "ger", so dropping it
  # would save another 12 MB, but the BibTeX and RIS exports read it and the
  # source XML does carry a per-file langcode. Hard-coding the language to save
  # a rounding error's worth of disk is not worth it.
  def up
    create_table :archive_locations do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :archive_locations, :name, unique: true

    execute(<<~SQL.squish)
      INSERT INTO archive_locations (name, created_at, updated_at)
      SELECT DISTINCT location, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM archive_files
      WHERE location IS NOT NULL
    SQL

    # No index on the reference: nothing queries archive files by location, and
    # nine distinct values over four million rows would barely narrow anything
    # down if something did. Indexing it costs 40 MB, which is most of what
    # normalising the column saves in the first place.
    add_reference :archive_files, :archive_location, index: false

    execute(<<~SQL.squish)
      UPDATE archive_files
      SET archive_location_id =
        (SELECT id FROM archive_locations WHERE archive_locations.name = archive_files.location)
      WHERE location IS NOT NULL
    SQL

    remove_column :archive_files, :location
  end

  def down
    add_column :archive_files, :location, :string

    execute(<<~SQL.squish)
      UPDATE archive_files
      SET location =
        (SELECT name FROM archive_locations WHERE archive_locations.id = archive_files.archive_location_id)
    SQL

    remove_reference :archive_files, :archive_location
    drop_table :archive_locations
  end
end
