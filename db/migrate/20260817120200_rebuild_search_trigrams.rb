class RebuildSearchTrigrams < ActiveRecord::Migration[8.1]
  # The old trigram table indexed the ancestor path and the origin names once
  # per archive file. Both are shared by many files at a time, so the trigram
  # index carried the same node names over and over: of the roughly 1.4 GB of
  # text fed to it, 915 MB was the ancestor path alone, which blew the index up
  # to 5.6 GB.
  #
  # Ancestor and origin names now get their own trigram tables, one row per node
  # and per origin instead of one per file, and ArchiveFile.search unions the
  # three together. That reproduces the old result set exactly while the index
  # shrinks to well under a fifth of its size.
  #
  # All three tables are contentless: nothing ever read a column value back out
  # of them, so there is no reason to keep a second copy of the text next to the
  # one in archive_files.

  OLD_TRIGRAMS = <<~SQL.squish
    CREATE VIRTUAL TABLE archive_file_trigrams USING fts5(
      archive_file_id UNINDEXED, archive_node_id UNINDEXED,
      title, summary, call_number, parents, origin_names,
      tokenize = 'trigram'
    )
  SQL

  def up
    execute("DROP TABLE IF EXISTS archive_file_trigrams")

    execute(<<~SQL.squish)
      CREATE VIRTUAL TABLE archive_file_trigrams USING fts5(
        title, summary, call_number,
        tokenize = 'trigram', content = '', contentless_delete = 1
      )
    SQL
    execute(<<~SQL.squish)
      CREATE VIRTUAL TABLE archive_node_trigrams USING fts5(
        name, tokenize = 'trigram', content = '', contentless_delete = 1
      )
    SQL
    execute(<<~SQL.squish)
      CREATE VIRTUAL TABLE origin_trigrams USING fts5(
        name, tokenize = 'trigram', content = '', contentless_delete = 1
      )
    SQL

    # Filling the tables straight from SQL keeps the whole rebuild inside SQLite
    # rather than walking four million rows through Active Record.
    execute(<<~SQL.squish)
      INSERT INTO archive_file_trigrams(rowid, title, summary, call_number)
      SELECT id, title, summary, call_number FROM archive_files
    SQL
    execute("INSERT INTO archive_node_trigrams(rowid, name) SELECT id, name FROM archive_nodes")
    execute("INSERT INTO origin_trigrams(rowid, name) SELECT id, name FROM origins")
  end

  def down
    execute("DROP TABLE IF EXISTS archive_file_trigrams")
    execute("DROP TABLE IF EXISTS archive_node_trigrams")
    execute("DROP TABLE IF EXISTS origin_trigrams")

    execute(OLD_TRIGRAMS)
    execute(<<~SQL.squish)
      INSERT INTO archive_file_trigrams(
        archive_file_id, archive_node_id, title, summary, call_number, parents, origin_names
      )
      SELECT f.id, f.archive_node_id, f.title, f.summary, f.call_number,
        (SELECT GROUP_CONCAT(JSON_EXTRACT(node.value, '$.name'), ' ')
         FROM JSON_EACH(f.parents) node),
        (SELECT GROUP_CONCAT(o.name, ' ')
         FROM originations n JOIN origins o ON o.id = n.origin_id
         WHERE n.archive_file_id = f.id)
      FROM archive_files f
    SQL
  end
end
