CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "cached_counts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "model" varchar, "scope" varchar, "count" bigint, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE IF NOT EXISTS "originations" ("record_id" bigint, "origin_id" bigint);
CREATE TABLE IF NOT EXISTS "origins" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "label" integer DEFAULT 0, "name" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar, "call_number" varchar, "source_date_text" varchar, "source_id" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "link" varchar, "location" varchar, "language_code" varchar, "summary" varchar, "parents" json DEFAULT '[]' NOT NULL, "source_date_start" date, "source_date_end" date, CONSTRAINT parents_is_array CHECK (JSON_TYPE(parents) = 'array'));
CREATE TABLE IF NOT EXISTS 'record_trigrams_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'record_trigrams_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'record_trigrams_content'(id INTEGER PRIMARY KEY, c0, c1, c2, c3, c4, c5);
CREATE TABLE IF NOT EXISTS 'record_trigrams_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'record_trigrams_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE UNIQUE INDEX "index_cached_counts_on_model_and_scope" ON "cached_counts" ("model", "scope");
CREATE INDEX "index_originations_on_origin_id" ON "originations" ("origin_id");
CREATE UNIQUE INDEX "index_originations_on_record_id_and_origin_id" ON "originations" ("record_id", "origin_id");
CREATE INDEX "index_originations_on_record_id" ON "originations" ("record_id");
CREATE UNIQUE INDEX "index_origins_on_label_and_name" ON "origins" ("label", "name");
CREATE INDEX "index_origins_on_name" ON "origins" ("name");
CREATE INDEX "index_records_on_call_number" ON "records" ("call_number");
CREATE UNIQUE INDEX "index_records_on_source_id" ON "records" ("source_id");
CREATE INDEX "index_records_on_summary" ON "records" ("summary");
CREATE INDEX "index_records_on_title_and_summary" ON "records" ("title", "summary");
CREATE INDEX "index_records_on_title" ON "records" ("title");
CREATE VIRTUAL TABLE record_trigrams USING fts5(record_id, title, summary, call_number, parents, origin_names, tokenize = 'trigram')
/* record_trigrams(record_id,title,summary,call_number,parents,origin_names) */;
INSERT INTO "schema_migrations" (version) VALUES
('20240510085044'),
('20240418135025');

