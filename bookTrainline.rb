# encoding: UTF-8
require 'rubygems'
require 'watir'
require 'json'
require 'rotp'
require 'time'
require 'sendgrid-ruby'
include SendGrid

File.open("run.log", 'a') {|f| f.write("----------\n") }

# Read json file
file = File.open("options.json", "r:UTF-8")
json_file = file.read
file.close

# Create json hash
$jsonFile = JSON.parse(json_file)

# Open browser and go to trainline website
$browser = Watir::Browser.new :chrome
$browser.goto "https://www.trainline.fr/search/"

# We can book a train 30 before start
$moreDays = 30

# Method to buy ticket on trainline
def buy_ticket (from, to, timeMin, timeMax, days, moreD)
	puts Date.today.to_s + " + "+ moreD.to_s + " days => " + Date.today.next_day(moreD).strftime('%a').to_s + " " + Date.today.next_day(moreD).to_s
	File.open("run.log", 'a') {|f| f.write(Date.today.to_s + " + "+ moreD.to_s + " days => " + Date.today.next_day(moreD).strftime('%a').to_s + " " + Date.today.next_day(moreD).to_s + "\n") }
	
	# Go to search page
	$browser.goto "https://www.trainline.fr/search/"+from+"/"+to+"/"+Date.today.next_day(moreD).to_s+"-"+timeMin.to_s+":00"
	
	puts "Search ticket from : "+from+" to : "+to
	File.open("run.log", 'a') {|f| f.write("Search ticket from : " + from + " to : "+ to + "\n") }
	
	# check first passager and TGVmax card
	if !$browser.span(:class => 'search__passengers--checkbox').class_name.include? "checked"
		$browser.span(:class => 'search__passengers--checkbox').checkbox().set
	end
	if !$browser.span(:class => 'card-item__checkbox').class_name.include? "checked"
		$browser.span(:class => 'card-item__checkbox').checkbox().set
	end
	
	# click on button search
	$browser.button(:class => 'progress-button__button').click

	# Wait to load all trains
	$browser.div(:class => 'progress-button__bar').wait_while_present
	
	while $browser.div(:class => 'form__errors').exist?
		puts "Error during Booking we retry"
		File.open("run.log", 'a') {|f| f.write("Error during Booking we retry\n") }
		sleep 5
		$browser.button(:class => 'progress-button__button').click
		$browser.div(:class => 'progress-button__bar').wait_while_present
	end
	
	line = $browser.divs(:class => 'search__results--line')
	
	line.each do |l|
		hours = l.span(:class => 'time')
		trainHour = /[0-9]{1,2}h/.match(hours.text.to_s).to_s
		trainHour = /[0-9]{1,2}/.match(trainHour).to_s
		trainMinute = /h[0-9]{1,2}/.match(hours.text.to_s).to_s
		trainMinute = /[0-9]{1,2}/.match(trainMinute).to_s
		trainTime = trainHour.to_s+":"+trainMinute.to_s
		if Time.parse(trainTime) >= Time.parse(timeMin) && Time.parse(trainTime) <= Time.parse(timeMax) && !l.div(:class => 'unsellable').exist?
			l.click
			sleep 2
			$browser.button(:class => 'progress-button__button')
			if $browser.button(:class => 'progress-button__button').exist?
				$browser.button(:class => 'progress-button__button').click
				$browser.button(:class => 'progress-button__button').wait_while_present
				if $browser.div(:class => 'form__errors').exist?
					puts "Error during booking from "+from+" to "+to
					File.open("run.log", 'a') {|f| f.write("Error during booking from " + from + " to " + to + "\n") }
					return false
				else
					$browser.button(:class => 'cart__button--pay').wait_until_present
					$browser.button(:class => 'cart__button--pay').click
					$browser.span(:class => 'checkbox--custom required').wait_until_present
					$browser.span(:class => 'checkbox--custom required').click
					$browser.button(:type => 'submit').click
					puts "Pay ticket from "+from+" to "+to
					File.open("run.log", 'a') {|f| f.write("Pay ticket from " + from + " to " + to + "\n") }
					sleep 5
					return true
				end
			end
		end
	end
	puts "No ticket find from : "+from+" to : "+to
	File.open("run.log", 'a') {|f| f.write("No ticket find from : " + from + " to : " + to + "\n") }
	return false
end


# Method to connect me on trainline with Google account
def connect_me (account, password, pin)
	# Connect me
	$browser.button(:class => 'header__signin-button').wait_until_present
	$browser.button(:class => 'header__signin-button').click
	$browser.button(:class => 'social-signin-google').wait_until_present
	sleep 2.456
	$browser.button(:class => 'social-signin-google').click
	
	if $browser.div(:class => 'form__errors').exist?
		puts "Error during Google connection"
		File.open("run.log", 'a') {|f| f.write("Error during Google connection\n") }
		return false
	else	
		# Set Google account informations in popup windows
		$browser.window(:index => 1).use do
			$browser.text_field(:id => 'identifierId').wait_until_present
			$browser.text_field(:id => 'identifierId').set account
			$browser.span(:text => 'Suivant').click

			$browser.text_field(:name => 'password').wait_until_present
			$browser.text_field(:name => 'password').set password
			$browser.span(:text => 'Suivant').click
			
			$totp = ROTP::TOTP.new(pin)
			
			$totpPin = $totp.now.to_s
			$browser.text_field(:id => 'totpPin').wait_until_present
			$browser.text_field(:id => 'totpPin').set $totpPin
			$browser.span(:text => 'Suivant').click
		end
	end	
end

# Connect to Trainline account
connect_me ENV["GOOGLE_EMAIL"], ENV["GOOGLE_PASSWORD"], ENV["GOOGLE_PIN"]
sleep 5

# For trip
$jsonFile["trip"].each do |trip|
	# Try to buy a ticket every week during $moreDays
	i = $moreDays
	while i >= 0
		if Date.today.next_day(i).strftime('%a') == trip["usual_day"]
			buyOne = buy_ticket trip["usual_from"], trip["usual_to"], trip["usual_departure_time_min"], trip["usual_departure_time_max"], trip["usual_day"], i
			if trip["from_option"][0]
				trip["from_option"].each do |from|
					if buyOne == false
						buyOne = buy_ticket from, trip["usual_to"], trip["usual_departure_time_min"], trip["usual_departure_time_max"], trip["usual_day"], i
					end
				end
			end
			if trip["to_option"][0]
				trip["to_option"].each do |to|
					if buyOne == false
						buyOne = buyOne = buy_ticket trip["usual_from"], to, trip["usual_departure_time_min"], trip["usual_departure_time_max"], trip["usual_day"], i
					end
				end
			end
		end
		i -= 1
	end
end

# For special trip
$jsonFile["special_trip"].each do |trip|
	i = $moreDays
	while i >= 0
		if Date.today.next_day(i).strftime('%Y-%m-%d') == trip["date"]
			buy_ticket trip["from"], trip["to"], trip["time_min"], trip["time_max"], trip["date"], i
		end
		i -= 1
	end
end

$browser.close

# Read run.log
line = ''
contentValue = ''
counter = 1
startLog = 1
file = File.new("run.log", "r")
while (line = file.gets)
  if line == "----------\n"
		startLog = counter
	end
  counter = counter + 1
end
file.close
counterBis = 1
file = File.new("run.log", "r")
while (line = file.gets)
		if counterBis > startLog
			contentValue = contentValue + line
		end
    counterBis = counterBis + 1
end
file.close

# Send email
from = Email.new(email: ENV["GOOGLE_EMAIL"])
to = Email.new(email: ENV["GOOGLE_EMAIL"])
subject = 'AutoTrain Script'
content = Content.new(type: 'text/plain', value: contentValue)
mail = Mail.new(from, subject, to, content)

sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
response = sg.client.mail._('send').post(request_body: mail.to_json)
puts 'Email sent : ' + response.status_code
File.open("run.log", 'a') {|f| f.write("Email sent : " + response.status_code + "\n") }
