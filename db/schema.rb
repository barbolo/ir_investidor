# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_12_14_123048) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "session_id"
    t.integer "row"
    t.string "asset_class"
    t.string "order_type"
    t.boolean "daytrade"
    t.string "name"
    t.integer "quantity"
    t.decimal "price", precision: 10, scale: 2
    t.decimal "costs", precision: 10, scale: 2
    t.decimal "irrf", precision: 10, scale: 2
    t.date "ordered_at"
    t.date "settlement_at"
    t.string "new_name"
    t.decimal "old_quantity", precision: 10, scale: 2
    t.decimal "new_quantity", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "ordered_at"], name: "index_orders_on_session_id_and_ordered_at"
  end

  create_table "session_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "session_id"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_session_logs_on_session_id"
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "secret", limit: 64
    t.boolean "sheet_ready"
    t.boolean "orders_ready"
    t.boolean "calcs_ready"
    t.integer "orders_count"
    t.decimal "assets_value", precision: 10, scale: 2
    t.string "error"
    t.timestamp "expire_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["secret"], name: "index_sessions_on_secret", unique: true
  end

  add_foreign_key "orders", "sessions"
  add_foreign_key "session_logs", "sessions"
end
