require 'open-uri'
require 'nokogiri'
require 'debug'
require 'CSV'

# 詳細ページに遷移する
# visit tourism_id each 190~683
urls = []
  (190..683).each do |i|
  urls = urls.push(%W(https://ja.kyoto.travel/tourism/single01.php?category_id=7&tourism_id=#{i}))
  end

# 詳細ページからデータを取得する
header = ['name', 'description', 'address', 'access', 'business_hours', 'holiday', 'phone_number', 'homepage']
rows = []
rows << header
# 欲しいデータのセレクタをリスト化する
begin
urls.each do |url| 
  file = url.join
  result = URI.open(file)
# Nokogiriを使用してdomを取得する(各データ分)
  doc = Nokogiri::HTML(result)
# 取得したdomからテキストを抽出する
  description = doc.at_css('p.mod_txt01.mod_inner02').inner_text
  element = doc.css('.mod_table01 td')
  name = element[0].inner_text
  address = element[4]
  access = element[5]
  business_hours = element[7]
  holiday = element[8]
  phone_number = element[9]
  homepage = element[10]
  rows << [name, description, address, access, business_hours, holiday, phone_number, homepage]
  rescue OpenURI::HTTPError  => e
    puts e  
    sleep 2
    next
  end
end

CSV.open("./temple_info.csv","w",:force_quotes=>true) do |csv|
  rows.each do |row|
    csv << row
    sleep 2
  end
end
