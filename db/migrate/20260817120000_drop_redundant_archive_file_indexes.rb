class DropRedundantArchiveFileIndexes < ActiveRecord::Migration[8.1]
  # Title and summary are only ever searched through the trigram index, never
  # through a WHERE or an ORDER BY on the table itself. The B-tree indexes over
  # those two long text columns cost about 1.2 GB and answer no query. The
  # single-column title index was redundant on top of that, being a strict
  # prefix of the composite one.
  def up
    remove_index :archive_files, %i[title summary]
    remove_index :archive_files, :summary
    remove_index :archive_files, :title
  end

  def down
    add_index :archive_files, :title
    add_index :archive_files, :summary
    add_index :archive_files, %i[title summary]
  end
end
