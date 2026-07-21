# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
require "csv"

# 神社の地域マスタ
CSV.foreach('db/csv/area.csv', headers: true) do |row|
  Area.find_or_create_by!(name: row['name'])
end

# 抹茶店のジャンルマスタ。抹茶店の紐付けはこのマスタに存在するジャンルのみ対象とし、
# CSV 側の表記揺れで未知のジャンルが来ても新規ジャンルは作らない（重複防止）
CSV.foreach('db/csv/genre.csv', headers: false) do |row|
  name = row[0].to_s.strip
  Genre.find_or_create_by!(name: name) unless name.empty?
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

CSV.foreach('db/csv/greentea_info.csv', headers: true) do |row|
  greentea = Greentea.find_or_initialize_by(name: row['name'], address: row['address'])
  greentea.assign_attributes(
    description: row['description'],
    phone_number: row['phone_number'],
    address: row['address'],
    access: row['access'],
    business_hours: row['business_hours'],
    homepage: row['homepage'],
    holiday: row['holiday']
  )
  greentea.save!

  # ジャンルは半角スペース区切り。マスタに存在するものだけ紐付ける
  genre_names = row['genre'].to_s.split(/[[:space:]]+/).reject(&:empty?)
  Genre.where(name: genre_names).each do |genre|
    greentea.greentea_genres.find_or_create_by!(genre: genre)
  end
end
