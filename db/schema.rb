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

ActiveRecord::Schema.define(version: 20170410133434) do

  create_table "books", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "parent_id"
    t.integer  "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_books_on_parent_id", using: :btree
    t.index ["user_id"], name: "index_books_on_user_id", using: :btree
  end

  create_table "brokers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "cnpj",         limit: 14
    t.text     "search_terms", limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["cnpj"], name: "index_brokers_on_cnpj", unique: true, using: :btree
    t.index ["name"], name: "index_brokers_on_name", using: :btree
  end

  create_table "holdings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "user_broker_id"
    t.integer  "book_id"
    t.string   "asset"
    t.string   "asset_name"
    t.string   "asset_identifier"
    t.integer  "quantity"
    t.decimal  "initial_price",     precision: 10, scale: 6
    t.decimal  "current_price",     precision: 10, scale: 6
    t.date     "last_operation_at"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.index ["book_id"], name: "index_holdings_on_book_id", using: :btree
    t.index ["user_broker_id"], name: "index_holdings_on_user_broker_id", using: :btree
    t.index ["user_id", "asset_identifier"], name: "index_holdings_on_user_id_and_asset_identifier", using: :btree
    t.index ["user_id"], name: "index_holdings_on_user_id", using: :btree
  end

  create_table "tax_entries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "tax_id"
    t.string   "asset"
    t.string   "asset_name"
    t.boolean  "daytrade"
    t.decimal  "net_earning",   precision: 10, scale: 2, default: "0.0"
    t.decimal  "aliquot",       precision: 3,  scale: 2, default: "0.0"
    t.decimal  "tax_value",     precision: 8,  scale: 2, default: "0.0"
    t.decimal  "irrf",          precision: 8,  scale: 2, default: "0.0"
    t.date     "operation_at"
    t.date     "settlement_at"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.index ["tax_id", "operation_at"], name: "index_tax_entries_on_tax_id_and_operation_at", using: :btree
    t.index ["tax_id"], name: "index_tax_entries_on_tax_id", using: :btree
  end

  create_table "taxes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.date     "period"
    t.decimal  "net_earnings",                   precision: 10, scale: 2, default: "0.0"
    t.decimal  "net_earnings_day_trade",         precision: 10, scale: 2, default: "0.0"
    t.decimal  "losses_accumulated",             precision: 10, scale: 2, default: "0.0"
    t.decimal  "losses_accumulated_day_trade",   precision: 10, scale: 2, default: "0.0"
    t.decimal  "irrf",                           precision: 8,  scale: 2, default: "0.0"
    t.decimal  "irrf_accumulated_to_compensate", precision: 8,  scale: 2, default: "0.0"
    t.decimal  "stock_sales",                    precision: 10, scale: 2, default: "0.0"
    t.decimal  "darf",                           precision: 8,  scale: 2, default: "0.0"
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
    t.index ["user_id", "period"], name: "index_taxes_on_user_id_and_period", using: :btree
    t.index ["user_id"], name: "index_taxes_on_user_id", using: :btree
  end

  create_table "transactions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "user_broker_id"
    t.integer  "book_id"
    t.string   "asset",           limit: 5
    t.string   "operation",       limit: 5
    t.string   "name",            limit: 100
    t.string   "ticker"
    t.decimal  "fixed_rate",                    precision: 5,  scale: 2
    t.string   "index_name"
    t.decimal  "index_rate",                    precision: 5,  scale: 4
    t.integer  "quantity"
    t.decimal  "price",                         precision: 7,  scale: 2
    t.decimal  "value",                         precision: 10, scale: 2
    t.text     "costs_breakdown", limit: 65535
    t.decimal  "costs",                         precision: 8,  scale: 2
    t.decimal  "irrf",                          precision: 8,  scale: 2
    t.date     "operation_at"
    t.date     "settlement_at"
    t.date     "expire_at"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.index ["book_id"], name: "index_transactions_on_book_id", using: :btree
    t.index ["operation_at", "user_id", "book_id"], name: "index_transactions_on_operation_at_and_user_id_and_book_id", using: :btree
    t.index ["user_broker_id"], name: "index_transactions_on_user_broker_id", using: :btree
    t.index ["user_id", "expire_at"], name: "index_transactions_on_user_id_and_expire_at", using: :btree
    t.index ["user_id"], name: "index_transactions_on_user_id", using: :btree
  end

  create_table "user_brokers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "broker_id"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["broker_id"], name: "index_user_brokers_on_broker_id", using: :btree
    t.index ["user_id"], name: "index_user_brokers_on_user_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  end

  add_foreign_key "books", "users"
  add_foreign_key "holdings", "books"
  add_foreign_key "holdings", "user_brokers"
  add_foreign_key "holdings", "users"
  add_foreign_key "tax_entries", "taxes"
  add_foreign_key "taxes", "users"
  add_foreign_key "transactions", "books"
  add_foreign_key "transactions", "user_brokers"
  add_foreign_key "transactions", "users"
  add_foreign_key "user_brokers", "brokers"
  add_foreign_key "user_brokers", "users"
end
