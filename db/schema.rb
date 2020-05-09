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

ActiveRecord::Schema.define(version: 2020_05_09_104732) do

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

  create_table "assets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "session_id"
    t.string "asset_class"
    t.string "name"
    t.integer "quantity"
    t.decimal "price", precision: 10, scale: 2, unsigned: true
    t.decimal "current_price", precision: 10, scale: 2, unsigned: true
    t.decimal "value", precision: 10, scale: 2
    t.decimal "current_value", precision: 10, scale: 2
    t.decimal "profit", precision: 10, scale: 2
    t.date "last_order_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "asset_class", "name"], name: "index_assets_on_session_id_and_asset_class_and_name"
  end

  create_table "assets_end_of_years", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "session_id"
    t.integer "year", limit: 2
    t.json "assets"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "year"], name: "index_assets_end_of_years_on_session_id_and_year"
  end

  create_table "orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "session_id"
    t.integer "row", unsigned: true
    t.string "asset_class"
    t.string "order_type"
    t.boolean "daytrade"
    t.string "name"
    t.integer "quantity", unsigned: true
    t.decimal "price", precision: 10, scale: 2, unsigned: true
    t.decimal "costs", precision: 10, scale: 2, unsigned: true
    t.decimal "irrf", precision: 10, scale: 2, unsigned: true
    t.date "ordered_at"
    t.date "settlement_at"
    t.string "new_name"
    t.decimal "old_quantity", precision: 10, scale: 2, unsigned: true
    t.decimal "new_quantity", precision: 10, scale: 2, unsigned: true
    t.decimal "accumulated_common", precision: 10, scale: 2, unsigned: true
    t.decimal "accumulated_daytrade", precision: 10, scale: 2, unsigned: true
    t.decimal "accumulated_fii", precision: 10, scale: 2, unsigned: true
    t.decimal "accumulated_irrf", precision: 10, scale: 2, unsigned: true
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
    t.integer "orders_count", unsigned: true
    t.decimal "assets_value", precision: 10, scale: 2
    t.string "error"
    t.timestamp "expire_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["secret"], name: "index_sessions_on_secret", unique: true
  end

  create_table "tax_entries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "tax_id"
    t.string "asset_class"
    t.string "name"
    t.boolean "daytrade"
    t.decimal "tax_aliquot", precision: 10, scale: 6, unsigned: true
    t.decimal "irrf_aliquot", precision: 10, scale: 6, unsigned: true
    t.decimal "earnings", precision: 10, scale: 2
    t.decimal "tax_due", precision: 10, scale: 2, unsigned: true
    t.decimal "irrf", precision: 10, scale: 2, unsigned: true
    t.datetime "disposed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_id", "asset_class", "disposed_at"], name: "index_tax_entries_on_tax_id_and_asset_class_and_disposed_at"
  end

  create_table "taxes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "session_id"
    t.date "period"
    t.decimal "darf", precision: 10, scale: 2, unsigned: true
    t.decimal "common_daytrade_darf", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_darf", precision: 10, scale: 2, unsigned: true
    t.decimal "stocks_sales", precision: 10, scale: 2, unsigned: true
    t.decimal "stocks_taxfree_profits", precision: 10, scale: 2, unsigned: true
    t.decimal "common_tax_aliquot", precision: 10, scale: 6, unsigned: true
    t.decimal "common_irrf_aliquot", precision: 10, scale: 6, unsigned: true
    t.decimal "common_stocks_earnings", precision: 10, scale: 2
    t.decimal "common_options_earnings", precision: 10, scale: 2
    t.decimal "common_subscriptions_earnings", precision: 10, scale: 2
    t.decimal "common_earnings", precision: 10, scale: 2
    t.decimal "common_sales", precision: 10, scale: 2, unsigned: true
    t.decimal "common_losses_before", precision: 10, scale: 2, unsigned: true
    t.decimal "common_taxable_value", precision: 10, scale: 2, unsigned: true
    t.decimal "common_losses_after", precision: 10, scale: 2, unsigned: true
    t.decimal "common_tax_due", precision: 10, scale: 2, unsigned: true
    t.decimal "common_irrf", precision: 10, scale: 2, unsigned: true
    t.decimal "common_irrf_before", precision: 10, scale: 2, unsigned: true
    t.decimal "common_irrf_after", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_tax_aliquot", precision: 10, scale: 6, unsigned: true
    t.decimal "daytrade_irrf_aliquot", precision: 10, scale: 6, unsigned: true
    t.decimal "daytrade_stocks_earnings", precision: 10, scale: 2
    t.decimal "daytrade_options_earnings", precision: 10, scale: 2
    t.decimal "daytrade_earnings", precision: 10, scale: 2
    t.decimal "daytrade_sales", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_losses_before", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_taxable_value", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_losses_after", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_tax_due", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_irrf", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_irrf_before", precision: 10, scale: 2, unsigned: true
    t.decimal "daytrade_irrf_after", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_tax_aliquot", precision: 10, scale: 6, unsigned: true
    t.decimal "fii_earnings", precision: 10, scale: 2
    t.decimal "fii_sales", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_losses_before", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_taxable_value", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_losses_after", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_tax_due", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_irrf", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_irrf_before", precision: 10, scale: 2, unsigned: true
    t.decimal "fii_irrf_after", precision: 10, scale: 2, unsigned: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "period"], name: "index_taxes_on_session_id_and_period"
  end

  create_table "tickers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "ticker", limit: 20
    t.string "cnpj", limit: 15
    t.text "razao_social", limit: 255
    t.text "trading_name", limit: 255
    t.text "fake_fulltext_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticker"], name: "index_tickers_on_ticker", unique: true
  end

  add_foreign_key "assets", "sessions"
  add_foreign_key "assets_end_of_years", "sessions"
  add_foreign_key "orders", "sessions"
  add_foreign_key "session_logs", "sessions"
  add_foreign_key "tax_entries", "taxes"
  add_foreign_key "taxes", "sessions"
end
