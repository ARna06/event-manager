require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(number)
  if (number.to_s.chars.length === 11) && number.to_s[0] ===1
    return number.to_s[1..10]
  elsif number.to_s.chars.length != 10
    return ''
  else return number
  end
end

def peak_evaluator(arr)
  tally = arr.reduce Hash.new(0) do |prev, item|
    prev[item.to_s] += 1
    prev
  end
  max_hours = tally.map {|k, v| k if v === tally.values.max}
  return max_hours.select { |item| item.to_s != '' }
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = []
week_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  hours.push(Time.strptime(row[:regdate].to_s, "%m/%d/%Y %k:%M").hour)
  week_days.push(Date::DAYNAMES[Date.strptime(row[:regdate].to_s, "%m/%d/%Y %k:%M").wday])

end

puts "The peak registration time is #{peak_evaluator(hours).join(', ')} hours respectively."
puts "The peak registration weekday is #{peak_evaluator(week_days).join(', ')} respectively."
