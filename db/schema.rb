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

ActiveRecord::Schema[8.1].define(version: 2026_04_08_000001) do
  create_table "facebook_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "facebook_post_id"
    t.string "image_url"
    t.text "message"
    t.string "post_url"
    t.datetime "published_at"
    t.datetime "updated_at", null: false
  end

  create_table "incidents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "notes", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.integer "info"
    t.datetime "updated_at", null: false
  end

  create_table "people", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.boolean "present", default: false
    t.datetime "updated_at", null: false
    t.boolean "volunteer", default: false
    t.index ["archived"], name: "index_people_on_archived"
    t.index ["name"], name: "index_people_on_name", unique: true
  end

  create_table "sign_ins", force: :cascade do |t|
    t.boolean "activity", default: false, null: false
    t.datetime "arrived_at"
    t.datetime "checked_in_at"
    t.datetime "checked_out_at"
    t.datetime "created_at", null: false
    t.boolean "has_car"
    t.boolean "has_pet"
    t.text "haven_notes"
    t.boolean "is_haven_checkin", default: false, null: false
    t.datetime "left_at"
    t.integer "num_children"
    t.integer "person_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "volunteer", default: false, null: false
    t.index ["person_id"], name: "index_sign_ins_on_person_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "sign_ins", "people"
end
