# Shared behaviour for the small trigram tables that index a single name column
# keyed by the record's own id: archive_node_trigrams and origin_trigrams.
#
# Both tables exist so that a search matching an archive node or an origin can
# reach the files underneath it without every file carrying its own copy of
# those names. They are contentless, so nothing reads a value back out of them;
# they only ever answer "which ids match this query".
module NameTrigramIndexed
  extend ActiveSupport::Concern

  included do
    after_create :insert_trigram
    after_update :update_trigram
    after_destroy :delete_trigram
  end

  class_methods do
    def trigram_table
      "#{model_name.singular}_trigrams"
    end

    def reindex
      connection.execute("DELETE FROM #{trigram_table}")
      connection.execute(
        "INSERT INTO #{trigram_table}(rowid, name) SELECT id, name FROM #{table_name}"
      )
    end
  end

  private

  def insert_trigram
    self.class.connection.execute(
      "INSERT INTO #{self.class.trigram_table}(rowid, name) " \
        "VALUES(#{id}, #{self.class.connection.quote(name)})"
    )
  end

  def delete_trigram
    self.class.connection.execute(
      "DELETE FROM #{self.class.trigram_table} WHERE rowid = #{attributes['id']}"
    )
  end

  # Not very efficient, but fine for now as this should basically never happen
  def update_trigram
    delete_trigram
    insert_trigram
  end
end
