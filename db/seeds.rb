# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
require "csv"

# CSV.foreach('db/csv/genre.csv') do |row|
#   Genre.find_or_create_by(:name => row[0])
# end

CSV.foreach('db/csv/greentea.csv', headers: true) do |row|
  greentea = Greentea.create(
    name: row['name'],
    description: row['description'], 
    phone_number: row['phone_number'],
    address: row['address'],
    access: row['access'],
    business_hours: row['business_hours'],
    homepage: row['homepage'],
    holiday: row['holiday'])
  genres = Genre.where(name: row['genre'].split(' '))
  genres.each do |genre|
    greentea.greentea_genres.create(genre: genre)
  end
end

# CSV.foreach('db/csv/area.csv', headers: true) do |row|
#   Area.find_or_create_by(name:row['name'])
# end

CSV.foreach('db/csv/temple.csv', headers: true) do |row|
  temple = Temple.create(
    name: row['name'],
    description: row['description'], 
    phone_number: row['phone_number'],
    address: row['address'],
    access: row['access'],
    business_hours: row['business_hours'],
    homepage: row['homepage'],
    holiday: row['holiday'])
  areas = Area.where(name: row['area'])
  areas.each do |area|
    temple.temple_areas.create(area: area)
  end
end