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

ActiveRecord::Schema[7.0].define(version: 2022_09_27_043522) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genres", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "greentea_genres", force: :cascade do |t|
    t.bigint "greentea_id", null: false
    t.bigint "genre_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_greentea_genres_on_genre_id"
    t.index ["greentea_id"], name: "index_greentea_genres_on_greentea_id"
  end

  create_table "greenteas", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "phone_number"
    t.string "address", null: false
    t.string "access", null: false
    t.string "business_hours"
    t.string "homepage"
    t.integer "closed"
    t.string "img"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "holiday"
    t.float "latitude"
    t.float "longitude"
  end

  create_table "temple_areas", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.bigint "area_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_temple_areas_on_area_id"
    t.index ["temple_id"], name: "index_temple_areas_on_temple_id"
  end

  create_table "temples", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "phone_number"
    t.string "address", null: false
    t.string "access", null: false
    t.string "business_hours"
    t.string "homepage"
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.string "holiday"
    t.string "img"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.string "name", default: "ユーザー", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "greentea_genres", "genres"
  add_foreign_key "greentea_genres", "greenteas"
  add_foreign_key "temple_areas", "areas"
  add_foreign_key "temple_areas", "temples"
end
