class AddSearchTable < ActiveRecord::Migration[7.1]
  def up
    execute(
      "CREATE VIRTUAL TABLE records_trigram USING fts5(record_id, title, summary, call_number UNINDEXED, parents, origin_names, tokenize = 'trigram')"
    )
  end

  def down
    execute("DROP TABLE IF EXISTS records_trigram")
  end
end
