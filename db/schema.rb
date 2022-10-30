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

ActiveRecord::Schema[7.0].define(version: 2022_10_19_014240) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authentications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_authentications_on_provider_and_uid"
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

  create_table "greentea_likes", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "greentea_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["greentea_id"], name: "index_greentea_likes_on_greentea_id"
    t.index ["user_id", "greentea_id"], name: "index_greentea_likes_on_user_id_and_greentea_id", unique: true
    t.index ["user_id"], name: "index_greentea_likes_on_user_id"
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
    t.string "name", default: "ユーザー", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "greentea_genres", "genres"
  add_foreign_key "greentea_genres", "greenteas"
  add_foreign_key "greentea_likes", "greenteas"
  add_foreign_key "greentea_likes", "users"
  add_foreign_key "temple_areas", "areas"
  add_foreign_key "temple_areas", "temples"
end
