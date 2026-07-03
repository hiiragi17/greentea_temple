# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
#
# ⚠️ Greentea / Temple は保存時に住所ジオコーディングを行う（app/models/*.rb の
#    `after_validation :geocode`）。この seed を流すと 1 レコードにつき Google Geocoding
#    API を 1 回叩くため、GOOGLE_GEOCODING_API_KEY の設定とクォータ/課金に注意すること。
#    詳細は docs/infra/deploy-runbook.md の「デプロイ前チェックリスト」を参照。
require "csv"

# ジャンル（抹茶店の分類）。genre.csv はヘッダなし・1 行 1 名称。
CSV.foreach('db/csv/genre.csv', headers: false) do |row|
  name = row[0].to_s.strip
  next if name.blank?

  Genre.find_or_create_by!(name: name)
end

# 抹茶スイーツ店。genre 列は半角スペース区切りの複数ジャンル。
CSV.foreach('db/csv/greentea_info.csv', headers: true) do |row|
  greentea = Greentea.find_or_initialize_by(name: row['name'], address: row['address'])
  greentea.assign_attributes(
    description: row['description'],
    phone_number: row['phone_number'],
    access: row['access'],
    business_hours: row['business_hours'],
    homepage: row['homepage'],
    holiday: row['holiday']
  )
  greentea.save!

  row['genre'].to_s.split(/[[:space:]]+/).each do |genre_name|
    name = genre_name.strip
    next if name.blank?

    genre = Genre.find_or_create_by!(name: name)
    greentea.greentea_genres.find_or_create_by!(genre: genre)
  end
end

CSV.foreach('db/csv/area.csv', headers: true) do |row|
  Area.find_or_create_by!(name: row['name'])
end

CSV.foreach('db/csv/temple_info.csv', headers: true) do |row|
  temple = Temple.find_or_initialize_by(name: row['name'], address: row['address'])
  temple.assign_attributes(
    description: row['description'],
    phone_number: row['phone_number'],
    address: row['address'],
    access: row['access'],
    business_hours: row['business_hours'],
    homepage: row['homepage'],
    holiday: row['holiday']
  )
  temple.save!

  area = Area.find_by!(name: row['area'])
  temple.temple_areas.find_or_create_by!(area: area)
end