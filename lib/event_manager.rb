require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


puts 'EventManager initialized.'

def clean_zipcodes(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcodes(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

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

def save_thank_you_letter(id, form_letter)
  filename = "output/thanks#{id}.html"
  return if File.exist?(filename)

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
  if phone_number.nil? || phone_number.length < 10 || (phone_number.length == 11 && phone_number[0] != '1') || phone_number.length > 11
    '0' * 10
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..]
  else
    phone_number
  end
end

def peak_registration_hours(registration_times)
  registration_hours = registration_times.map { |time_object| time_object.hour }

  registration_hours.sort_by { |hour| registration_hours.count(hour)}.reverse.uniq[..2]
end

def peak_registration_days(registration_times)
  registration_days = registration_times.map { |time_object| time_object.strftime("%A") }

  registration_days.sort_by { |day| registration_days.count(day)}.reverse.uniq[..2]
end

contents = CSV.open('event_attendees.csv', headers: true, 
header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
Dir.mkdir('output') unless Dir.exist?('output')


registration_times = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  time = Time.strptime(row[:regdate], "%m/%d/%y %k:%M")

  registration_times.push(time)

  zipcode = clean_zipcodes(row[:zipcode])
  legislators = legislators_by_zipcodes(zipcode)
  
  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id, form_letter)

end

puts "The peak registration hours are : #{peak_registration_hours(registration_times).join(", ")}"
puts "The peak registration days are : #{peak_registration_days(registration_times).join(", ")}"