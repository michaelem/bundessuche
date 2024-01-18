# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_01_16_094116) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "cached_counts", force: :cascade do |t|
    t.string "model"
    t.string "scope"
    t.bigint "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model", "scope"], name: "index_cached_counts_on_model_and_scope", unique: true
  end

  create_table "records", force: :cascade do |t|
    t.string "title"
    t.string "call_number"
    t.string "source_date"
    t.string "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "link"
    t.string "location"
    t.string "language_code"
    t.string "summary"
    t.index "to_tsvector('german'::regconfig, (((((title)::text || ' '::text) || (call_number)::text) || ' '::text) || (summary)::text))", name: "records_search", using: :gin
    t.index ["call_number"], name: "index_records_on_call_number"
    t.index ["source_id"], name: "index_records_on_source_id", unique: true
    t.index ["title", "summary"], name: "index_records_on_title_and_summary", opclass: :gin_trgm_ops, using: :gin
  end

end
