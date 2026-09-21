# frozen_string_literal: true

# FTS5 keeps a handful of shadow tables behind each virtual table. SQLite dumps
# them alongside everything else, and once a table rebuild has shuffled the order
# of sqlite_master they can land ahead of the CREATE VIRTUAL TABLE that owns
# them. Loading such a dump fails: the virtual table cannot be created because
# its own shadow tables already exist, and the result is a database with no
# search tables at all.
#
# Creating the virtual table brings the shadow tables back by itself, so the
# safest thing is to keep them out of structure.sql entirely.
namespace :db do
  namespace :structure do
    task :drop_fts_shadow_tables do
      path = Rails.root.join('db/structure.sql')
      next unless File.exist?(path)

      shadow_table =
        /^CREATE TABLE (?:IF NOT EXISTS )?'[a-z_]+_trigrams_(?:data|idx|docsize|config|content)'[^\n]*\n/

      original = File.read(path)
      cleaned = original.gsub(shadow_table, '')
      File.write(path, cleaned) unless cleaned == original
    end
  end
end

Rake::Task['db:schema:dump'].enhance do
  Rake::Task['db:structure:drop_fts_shadow_tables'].invoke
end
