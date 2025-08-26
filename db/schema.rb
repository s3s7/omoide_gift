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

ActiveRecord::Schema[7.2].define(version: 2025_08_26_095748) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ages", force: :cascade do |t|
    t.string "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.string "body"
    t.bigint "user_id", null: false
    t.bigint "gift_record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_record_id"], name: "index_comments_on_gift_record_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "gift_record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_record_id"], name: "index_favorites_on_gift_record_id"
    t.index ["user_id", "gift_record_id"], name: "index_favorites_on_user_id_and_gift_record_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "gift_item_categories", force: :cascade do |t|
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
    t.string "gift_peoples_image"
    t.bigint "user_id", null: false
    t.bigint "relationship_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address", comment: "住所"
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
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "gift_people_id", null: false
    t.bigint "age_id"
    t.bigint "gift_item_category_id"
    t.boolean "commentable", default: true, null: false
    t.index ["age_id"], name: "index_gift_records_on_age_id"
    t.index ["event_id"], name: "index_gift_records_on_event_id"
    t.index ["gift_item_category_id"], name: "index_gift_records_on_gift_item_category_id"
    t.index ["gift_people_id"], name: "index_gift_records_on_gift_people_id"
    t.index ["user_id"], name: "index_gift_records_on_user_id"
  end

  create_table "relationships", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reminds", force: :cascade do |t|
    t.date "notification_at"
    t.datetime "notification_sent_at"
    t.boolean "is_sent"
    t.bigint "user_id", null: false
    t.bigint "gift_person_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_person_id"], name: "index_reminds_on_gift_person_id"
    t.index ["user_id"], name: "index_reminds_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.integer "role", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "gift_records"
  add_foreign_key "comments", "users"
  add_foreign_key "favorites", "gift_records"
  add_foreign_key "favorites", "users"
  add_foreign_key "gift_people", "relationships"
  add_foreign_key "gift_people", "users"
  add_foreign_key "gift_records", "ages"
  add_foreign_key "gift_records", "events"
  add_foreign_key "gift_records", "gift_item_categories"
  add_foreign_key "gift_records", "gift_people", column: "gift_people_id"
  add_foreign_key "gift_records", "users"
  add_foreign_key "reminds", "gift_people"
  add_foreign_key "reminds", "users"
end
