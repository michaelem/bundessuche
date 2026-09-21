# frozen_string_literal: true

class StoreSourceUuidAndLinkVariant < ActiveRecord::Migration[8.1]
  # source_id was "DE-1958_<uuid>" on every one of the four million rows and link
  # was one of two Invenio templates wrapped around that same uuid, so between
  # them the two columns and the unique index cost about 650 MB to store the same
  # sixteen bytes three times over.
  #
  # The uuid now lives once, as raw bytes, next to a template number. source_id
  # and link come back as generated columns: SQLite rebuilds the text on read, it
  # occupies no space on disk, and queries against either column still work.

  # The uuid in its canonical dashed form, rebuilt from the stored bytes.
  UUID_TEXT = <<~SQL.squish
    substr(lower(hex(source_uuid)), 1, 8) || '-' ||
    substr(lower(hex(source_uuid)), 9, 4) || '-' ||
    substr(lower(hex(source_uuid)), 13, 4) || '-' ||
    substr(lower(hex(source_uuid)), 17, 4) || '-' ||
    substr(lower(hex(source_uuid)), 21, 12)
  SQL

  INVENIO_LINK = 'https://invenio.bundesarchiv.de/invenio/direktlink/'
  BASYS2_LINK = 'https://invenio.bundesarchiv.de/basys2-invenio/direktlink/'

  def up
    add_column :archive_files, :source_uuid, :binary
    add_column :archive_files, :link_variant, :integer

    execute(
      "UPDATE archive_files SET source_uuid = unhex(replace(substr(source_id, 9), '-', ''))"
    )
    execute(<<~SQL.squish)
      UPDATE archive_files SET link_variant = CASE
        WHEN link LIKE '#{INVENIO_LINK}%/' THEN 0
        WHEN link LIKE '#{BASYS2_LINK}%/' THEN 1
      END
    SQL

    # Stop before dropping anything if a single row would not survive the round
    # trip, rather than discovering it once the originals are gone.
    unconvertible =
      select_value(<<~SQL.squish)
        SELECT count(*) FROM archive_files
        WHERE source_uuid IS NULL OR length(source_uuid) <> 16
           OR (link IS NOT NULL AND link_variant IS NULL)
      SQL
    raise "#{unconvertible} archive files do not match the expected id or link format" if unconvertible.to_i > 0

    remove_index :archive_files, :source_id
    remove_column :archive_files, :source_id
    remove_column :archive_files, :link

    execute(<<~SQL.squish)
      ALTER TABLE archive_files ADD COLUMN source_id TEXT
      GENERATED ALWAYS AS ('DE-1958_' || #{UUID_TEXT}) VIRTUAL
    SQL
    execute(<<~SQL.squish)
      ALTER TABLE archive_files ADD COLUMN link TEXT
      GENERATED ALWAYS AS (
        CASE link_variant
          WHEN 0 THEN '#{INVENIO_LINK}' || #{UUID_TEXT} || '/'
          WHEN 1 THEN '#{BASYS2_LINK}' || #{UUID_TEXT} || '/'
        END
      ) VIRTUAL
    SQL

    add_index :archive_files, :source_uuid, unique: true
  end

  def down
    remove_index :archive_files, :source_uuid
    execute('ALTER TABLE archive_files DROP COLUMN source_id')
    execute('ALTER TABLE archive_files DROP COLUMN link')

    add_column :archive_files, :source_id, :string
    add_column :archive_files, :link, :string

    execute("UPDATE archive_files SET source_id = 'DE-1958_' || #{UUID_TEXT}")
    execute(<<~SQL.squish)
      UPDATE archive_files SET link = CASE link_variant
        WHEN 0 THEN '#{INVENIO_LINK}' || #{UUID_TEXT} || '/'
        WHEN 1 THEN '#{BASYS2_LINK}' || #{UUID_TEXT} || '/'
      END
    SQL

    add_index :archive_files, :source_id, unique: true

    remove_column :archive_files, :source_uuid
    remove_column :archive_files, :link_variant
  end
end
