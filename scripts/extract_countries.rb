#encoding: UTF-8

require 'json'

# @file = IO.read(file).force_encoding("ISO-8859-1").encode("utf-8", replace: nil)

filepath = "countries.json"
countries = JSON.parse IO.read(filepath).force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
countries["features"].each do |country|
  name = country["properties"]["name"]
  text = country.to_json
  text = text.encode!('UTF-8', 'UTF-8', :invalid => :replace, :force_encoding => true)
  text.force_encoding('UTF-8')
  # text.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
  # text.encode!('UTF-8', 'UTF-16')

  puts name
  File.open("app/assets/countries/#{name}.geo.json", 'w:UTF-8') { |file| file.write(text) }
end

