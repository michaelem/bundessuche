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

ActiveRecord::Schema[7.1].define(version: 2024_05_10_085044) do
  create_table "cached_counts", force: :cascade do |t|
    t.string "model"
    t.string "scope"
    t.bigint "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model", "scope"], name: "index_cached_counts_on_model_and_scope", unique: true
  end

  create_table "originations", id: false, force: :cascade do |t|
    t.bigint "record_id"
    t.bigint "origin_id"
    t.index ["origin_id"], name: "index_originations_on_origin_id"
    t.index ["record_id", "origin_id"], name: "index_originations_on_record_id_and_origin_id", unique: true
    t.index ["record_id"], name: "index_originations_on_record_id"
  end

  create_table "origins", force: :cascade do |t|
    t.integer "label", default: 0
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label", "name"], name: "index_origins_on_label_and_name", unique: true
    t.index ["name"], name: "index_origins_on_name"
  end

# Could not dump table "record_trigrams" because of following StandardError
#   Unknown type '' for column 'record_id'

# Could not dump table "record_trigrams_config" because of following StandardError
#   Unknown type '' for column 'k'

# Could not dump table "record_trigrams_content" because of following StandardError
#   Unknown type '' for column 'c0'

  create_table "record_trigrams_data", force: :cascade do |t|
    t.binary "block"
  end

  create_table "record_trigrams_docsize", force: :cascade do |t|
    t.binary "sz"
  end

# Could not dump table "record_trigrams_idx" because of following StandardError
#   Unknown type '' for column 'segid'

  create_table "records", force: :cascade do |t|
    t.string "title"
    t.string "call_number"
    t.string "source_date_text"
    t.string "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "link"
    t.string "location"
    t.string "language_code"
    t.string "summary"
    t.json "parents", default: [], null: false
    t.date "source_date_start"
    t.date "source_date_end"
    t.index ["call_number"], name: "index_records_on_call_number"
    t.index ["source_id"], name: "index_records_on_source_id", unique: true
    t.index ["summary"], name: "index_records_on_summary"
    t.index ["title", "summary"], name: "index_records_on_title_and_summary"
    t.index ["title"], name: "index_records_on_title"
    t.check_constraint "JSON_TYPE(parents) = 'array'", name: "parents_is_array"
  end

end
