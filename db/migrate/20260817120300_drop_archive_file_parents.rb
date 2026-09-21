# frozen_string_literal: true

class DropArchiveFileParents < ActiveRecord::Migration[8.1]
  # The parents column repeated the whole ancestor chain, names and all, as JSON
  # on every archive file: 1.4 GB for roughly half a million distinct chains
  # across four million rows. archive_nodes already describes that tree through
  # parent_node_id, and the last entry of every chain was always the file's own
  # archive_node_id, so the column held nothing the tree could not answer.
  #
  # ArchiveFile#parents now walks the tree instead, in one recursive query per
  # page of results rather than one per row.

  def up
    # The check constraint mentions the column, so SQLite refuses to drop the
    # column while it is still in place.
    remove_check_constraint :archive_files, name: 'parents_is_array'
    remove_column :archive_files, :parents
  end

  def down
    add_column :archive_files, :parents, :json, null: false, default: []

    # Rebuild each chain root first, the way the importer used to write it.
    execute(<<~SQL.squish)
      WITH RECURSIVE chain(start_id, id, depth) AS (
        SELECT id, id, 0 FROM archive_nodes
        UNION ALL
        SELECT c.start_id, n.parent_node_id, c.depth + 1
        FROM archive_nodes n JOIN chain c ON n.id = c.id
        WHERE n.parent_node_id IS NOT NULL
      ),
      paths AS (
        SELECT c.start_id,
               JSON_GROUP_ARRAY(
                 JSON_OBJECT('name', a.name, 'id', a.id) ORDER BY c.depth DESC
               ) AS chain_json
        FROM chain c JOIN archive_nodes a ON a.id = c.id
        GROUP BY c.start_id
      )
      UPDATE archive_files
      SET parents = COALESCE(
        (SELECT chain_json FROM paths WHERE paths.start_id = archive_files.archive_node_id),
        '[]'
      )
    SQL

    add_check_constraint :archive_files,
                         "JSON_TYPE(parents) = 'array'",
                         name: 'parents_is_array'
  end
end
