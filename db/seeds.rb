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

# CSV.foreach('db/csv/greentea.csv', headers: true) do |row|
#   greentea = Greentea.find_or_create_by(
#     name: row['name'],
#     description: row['description'], 
#     phone_number: row['phone_number'],
#     address: row['address'],
#     access: row['access'],
#     business_hours: row['business_hours'],
#     homepage: row['homepage'],
#     holiday: row['holiday'])
#   genres = Genre.where(name: row['genre'].split(' '))
#   genres.each do |genre|
#     greentea.greentea_genres.create(genre: genre)
#   end
# end

CSV.foreach('db/csv/area.csv', headers: true) do |row|
  Area.find_or_create_by(name: row['name'])
end

CSV.foreach('db/csv/temple_info.csv', headers: true) do |row|
  temple = Temple.find_or_initialize_by(name: row['name'])
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