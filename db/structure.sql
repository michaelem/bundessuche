CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "origins" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "label" integer DEFAULT 0, "name" varchar);
CREATE TABLE IF NOT EXISTS "cached_counts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "model" varchar, "scope" varchar, "count" integer);
CREATE TABLE IF NOT EXISTS "archive_nodes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "parent_node_id" integer, "source_id" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "level" varchar);
CREATE TABLE IF NOT EXISTS "originations" ("archive_file_id" integer DEFAULT NULL, "origin_id" integer DEFAULT NULL);
CREATE TABLE IF NOT EXISTS "parsed_source_dates" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "source_text" varchar NOT NULL, "start_date" date, "end_date" date, "confidence" float, "llm_model" varchar, "raw_response" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "archive_locations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS 'archive_file_trigrams_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'archive_file_trigrams_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'archive_file_trigrams_docsize'(id INTEGER PRIMARY KEY, sz BLOB, origin INTEGER);
CREATE TABLE IF NOT EXISTS 'archive_file_trigrams_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'archive_node_trigrams_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'archive_node_trigrams_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'archive_node_trigrams_docsize'(id INTEGER PRIMARY KEY, sz BLOB, origin INTEGER);
CREATE TABLE IF NOT EXISTS 'archive_node_trigrams_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'origin_trigrams_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'origin_trigrams_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'origin_trigrams_docsize'(id INTEGER PRIMARY KEY, sz BLOB, origin INTEGER);
CREATE TABLE IF NOT EXISTS 'origin_trigrams_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE UNIQUE INDEX "index_origins_on_label_and_name" ON "origins" ("label", "name");
CREATE INDEX "index_origins_on_name" ON "origins" ("name");
CREATE UNIQUE INDEX "index_cached_counts_on_model_and_scope" ON "cached_counts" ("model", "scope");
CREATE INDEX "index_archive_nodes_on_source_id" ON "archive_nodes" ("source_id");
CREATE INDEX "index_archive_nodes_on_parent_node_id" ON "archive_nodes" ("parent_node_id");
CREATE INDEX "index_originations_on_origin_id" ON "originations" ("origin_id");
CREATE UNIQUE INDEX "index_originations_on_archive_file_id_and_origin_id" ON "originations" ("archive_file_id", "origin_id");
CREATE INDEX "index_originations_on_archive_file_id" ON "originations" ("archive_file_id");
CREATE UNIQUE INDEX "index_parsed_source_dates_on_source_text" ON "parsed_source_dates" ("source_text") /*application='Bundessuche'*/;
CREATE UNIQUE INDEX "index_archive_locations_on_name" ON "archive_locations" ("name") /*application='Bundessuche'*/;
CREATE VIRTUAL TABLE archive_file_trigrams USING fts5( title, summary, call_number, tokenize = 'trigram', content = '', contentless_delete = 1 )
/* archive_file_trigrams(title,summary,call_number) */;
CREATE VIRTUAL TABLE archive_node_trigrams USING fts5( name, tokenize = 'trigram', content = '', contentless_delete = 1 )
/* archive_node_trigrams(name) */;
CREATE VIRTUAL TABLE origin_trigrams USING fts5( name, tokenize = 'trigram', content = '', contentless_delete = 1 )
/* origin_trigrams(name) */;
CREATE TABLE IF NOT EXISTS "archive_files" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "title" varchar, "summary" varchar, "call_number" varchar, "source_date_text" varchar, "source_id" varchar, "link" varchar, "language_code" varchar, "source_date_start" date, "source_date_end" date, "archive_node_id" integer, "archive_location_id" integer);
CREATE INDEX "index_archive_files_on_archive_node_id" ON "archive_files" ("archive_node_id") /*application='Bundessuche'*/;
CREATE UNIQUE INDEX "index_archive_files_on_source_id" ON "archive_files" ("source_id") /*application='Bundessuche'*/;
CREATE INDEX "index_archive_files_on_call_number" ON "archive_files" ("call_number") /*application='Bundessuche'*/;
CREATE INDEX "index_archive_files_on_source_date_text" ON "archive_files" ("source_date_text") /*application='Bundessuche'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20260817120300'),
('20260817120200'),
('20260817120100'),
('20260817120000'),
('20260724204439'),
('20240826215919'),
('20240825103844'),
('20240825102326'),
('20240825095047'),
('20240825093053'),
('20240825083132'),
('20240811213335'),
('20240811202445'),
('20240510085044'),
('20240418135025');

