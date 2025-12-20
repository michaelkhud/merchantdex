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

ActiveRecord::Schema[8.1].define(version: 2025_12_20_082407) do
  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.string "counterparty"
    t.datetime "created_at", null: false
    t.decimal "crypto_amount", precision: 20, scale: 8
    t.string "cryptocurrency"
    t.string "local_currency"
    t.decimal "local_currency_amount", precision: 15, scale: 2
    t.decimal "market_value", precision: 15, scale: 2
    t.string "offer_uuid"
    t.string "platform", null: false
    t.string "status", null: false
    t.datetime "time_completed"
    t.datetime "time_created"
    t.string "trade_type", null: false
    t.decimal "trading_fee", precision: 15, scale: 8
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "uuid", null: false
    t.index ["user_id", "platform", "uuid"], name: "index_trades_on_user_platform_uuid", unique: true
    t.index ["user_id", "platform"], name: "index_trades_on_user_id_and_platform"
    t.index ["user_id", "status"], name: "index_trades_on_user_id_and_status"
    t.index ["user_id", "time_completed"], name: "index_trades_on_user_id_and_time_completed"
    t.index ["user_id", "trade_type"], name: "index_trades_on_user_id_and_trade_type"
    t.index ["user_id"], name: "index_trades_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "email_verification_code"
    t.datetime "email_verification_sent_at"
    t.datetime "email_verified_at"
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "trades", "users"
end
