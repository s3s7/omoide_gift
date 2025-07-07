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

ActiveRecord::Schema[7.2].define(version: 2025_07_07_125817) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gift_people", force: :cascade do |t|
    t.string "name"
    t.string "likes"
    t.string "dislikes"
    t.date "birthday"
    t.string "memo"
    t.string "gift_persons_image"
    t.bigint "user_id", null: false
    t.bigint "gift_record_id", null: false
    t.bigint "relationship_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_record_id"], name: "index_gift_people_on_gift_record_id"
    t.index ["relationship_id"], name: "index_gift_people_on_relationship_id"
    t.index ["user_id"], name: "index_gift_people_on_user_id"
  end

  create_table "gift_records", force: :cascade do |t|
    t.string "memo"
    t.string "gift_image"
    t.string "item_name"
    t.integer "amount"
    t.boolean "is_public"
    t.date "gift_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "event_id"
    t.bigint "gift_person_id"
    t.index ["event_id"], name: "index_gift_records_on_event_id"
    t.index ["gift_person_id"], name: "index_gift_records_on_gift_person_id"
    t.index ["user_id"], name: "index_gift_records_on_user_id"
  end

  create_table "relationships", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "gift_people", "gift_records"
  add_foreign_key "gift_people", "relationships"
  add_foreign_key "gift_people", "users"
  add_foreign_key "gift_records", "events"
  add_foreign_key "gift_records", "gift_people"
  add_foreign_key "gift_records", "users"
end
