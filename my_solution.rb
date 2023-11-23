require "http"
require "json"
require "ascii_charts"

line_width = 80

puts "=" * line_width
puts "Will you need an umbrella today?".center(line_width)
puts "=" * line_width
puts
puts "Where are you?"
location= gets.chomp
puts "Checking the weather for #{location}..."


gmaps_key = ENV.fetch("GMAPS_KEY")

gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{location}&key=#{gmaps_key}"

gmaps_data = HTTP.get(gmaps_url)
#puts gmaps_data
parsed_data = JSON.parse(gmaps_data)
#puts parsed_data
results_array = parsed_data.fetch("results")
#puts results_array
result_hash = results_array.at(0)
#puts result_hash
geo_hash = result_hash.fetch("geometry")
#puts geo_hash
location_hash = geo_hash.fetch("location")
#puts location_hash
latitude = location_hash.fetch("lat")
longitude = location_hash.fetch("lng")

puts "Your coordinates are #{latitude}, #{longitude}."

pirate_key = ENV.fetch("PIRATE_WEATHER_KEY")

pirate_weather_url = "https://api.pirateweather.net/forecast/#{pirate_key}/#{latitude},#{longitude}"

raw_data = HTTP.get(pirate_weather_url)
parsed_pirate_data = JSON.parse(raw_data)
current_hash = parsed_pirate_data.fetch("currently")
current_temp = current_hash.fetch("temperature")

puts "Its is currently #{current_temp} F."

minute_hash = parsed_pirate_data.fetch("minutely", false)

if minute_hash
  next_hour = minute_hash.fetch("summary")

  puts "Next hour: #{next_hour}"
end


hourly_hash = parsed_pirate_data.fetch("hourly")

hourly_data_array = hourly_hash.fetch("data")

next_twelve_hours = hourly_data_array[1..12]

precip_prob_threshold = 0.10

any_precipitation = false

next_twelve_hours.each do |hour_hash|
  precip_prob = hour_hash.fetch("precipProbability")

  if precip_prob > precip_prob_threshold
    any_precipitation = true

    precip_time = Time.at(hour_hash.fetch("time"))

    seconds_from_now = precip_time - Time.now

    hours_from_now = seconds_from_now / 60 / 60

    puts "In #{hours_from_now.round} hours, there is a #{(precip_prob * 100).round}% chance of precipitation."
    chart_data = []
    
  end
end
chart_data = []

next_twelve_hours.each_with_index do |hour_hash, index|
  precip_prob = hour_hash.fetch("precipProbability") * 100
  chart_data << [index + 1, precip_prob.round]  # +1 so hours start from 1 instead of 0
end

# Now draw the chart
puts "\nHours from now vs Precipitation probability\n\n"
puts AsciiCharts::Cartesian.new(chart_data, bar: true, hide_zero: true).draw

# Check for any precipitation
any_precipitation = chart_data.any? { |_, prob| prob > precip_prob_threshold * 100 }

if any_precipitation == true
  puts "You might want to take an umbrella!"
else
  puts "You probably won't need an umbrella."
end
