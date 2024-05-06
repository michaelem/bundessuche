class InitSchema < ActiveRecord::Migration[7.1]
  def up
    # These are extensions that must be enabled in order to support this database
    enable_extension "pg_trgm"
    enable_extension "plpgsql"
    create_table "cached_counts" do |t|
      t.string "model"
      t.string "scope"
      t.bigint "count"

      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index %w[model scope],
              name: "index_cached_counts_on_model_and_scope",
              unique: true
    end

    create_table "originations", id: false do |t|
      t.bigint "record_id"
      t.bigint "origin_id"

      t.index ["origin_id"], name: "index_originations_on_origin_id"
      t.index %w[record_id origin_id],
              name: "index_originations_on_record_id_and_origin_id",
              unique: true
      t.index ["record_id"], name: "index_originations_on_record_id"
    end

    create_table "origins" do |t|
      t.integer "label", default: 0
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false

      t.index %w[label name],
              name: "index_origins_on_label_and_name",
              unique: true
      t.index ["name"],
              name: "index_origins_on_name",
              opclass: :gin_trgm_ops,
              using: :gin
    end

    create_table "records" do |t|
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

      # Use a JSON column for the parents array as a replacement for the Postgres array type:
      # https://fractaledmind.github.io/2023/09/12/enhancing-rails-sqlite-array-columns/
      t.json "parents", default: [], null: false
      t.check_constraint "JSON_TYPE(parents) = 'array'",
                         name: "parents_is_array"

      t.date "source_date_start"
      t.date "source_date_end"

      t.index ["call_number"], name: "index_records_on_call_number"
      t.index ["source_id"], name: "index_records_on_source_id", unique: true
      t.index ["summary"],
              name: "index_records_on_summary",
              opclass: :gin_trgm_ops,
              using: :gin
      t.index %w[title summary],
              name: "index_records_on_title_and_summary",
              opclass: :gin_trgm_ops,
              using: :gin
      t.index ["title"],
              name: "index_records_on_title",
              opclass: :gin_trgm_ops,
              using: :gin
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "The initial migration is not revertable"
  end
end
