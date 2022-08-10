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

ActiveRecord::Schema[7.0].define(version: 2022_08_10_083959) do
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

  create_table "place_areas", force: :cascade do |t|
    t.bigint "place_id", null: false
    t.bigint "area_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_place_areas_on_area_id"
    t.index ["place_id"], name: "index_place_areas_on_place_id"
  end

  create_table "place_genres", force: :cascade do |t|
    t.bigint "place_id", null: false
    t.bigint "genre_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_place_genres_on_genre_id"
    t.index ["place_id"], name: "index_place_genres_on_place_id"
  end

  create_table "places", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "phone_number"
    t.string "address", null: false
    t.string "access", null: false
    t.datetime "open_time"
    t.datetime "close_time"
    t.string "homepage"
    t.integer "latitude", null: false
    t.integer "longitude", null: false
    t.integer "place_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "place_areas", "areas"
  add_foreign_key "place_areas", "places"
  add_foreign_key "place_genres", "genres"
  add_foreign_key "place_genres", "places"
end
