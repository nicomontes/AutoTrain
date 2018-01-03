# encoding: UTF-8
require 'rubygems'
require 'watir'
require 'json'
require 'rotp'
require 'time'

# Read json file
file = File.open("options.json", "r:UTF-8")
json_file = file.read
file.close

# Create json hash
$jsonFile = JSON.parse(json_file)

# Open browser and go to trainline website
$browser = Watir::Browser.new :chrome
$browser.goto "https://www.trainline.fr/search/"

# We can book a train 30 or 3 days before start
$moreDays = 30
$moreDaysBis = 3

puts Date.today.to_s + " + 30 days => " + Date.today.next_day($moreDays).to_s
puts Date.today.to_s + " + 3 days => " + Date.today.next_day($moreDaysBis).to_s
File.open("run.log", 'a') {|f| f.write(Date.today.to_s + " + 30 days => " + Date.today.next_day($moreDays).to_s + "\n") }
File.open("run.log", 'a') {|f| f.write(Date.today.to_s + " + 3 days => " + Date.today.next_day($moreDaysBis).to_s + "\n") }

# Method to buy ticket on trainline
def buy_ticket (from, to, timeMin, timeMax, days)
	# Go to search page
	if Date.today.next_day($moreDays).strftime('%a') == days
		$browser.goto "https://www.trainline.fr/search/"+from+"/"+to+"/"+Date.today.next_day($moreDays).to_s+"-"+timeMin.to_s+":00"
	else
		 $browser.goto "https://www.trainline.fr/search/"+from+"/"+to+"/"+Date.today.next_day($moreDaysBis).to_s+"-"+timeMin.to_s+":00"
	end
	
	puts "Search ticket from : "+from+" to : "+to
	File.open("run.log", 'a') {|f| f.write("Search ticket from : " + from + " to : "+ to + "\n") }
	
	# click on button search
	$browser.button(:class => 'progress-button--button').click

	# Wait to load all trains
	$browser.div(:class => 'progress-button--bar').wait_while_present
	
	
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
			$browser.button(:class => 'progress-button--button')
			if $browser.button(:class => 'progress-button--button').exist?
				$browser.button(:class => 'progress-button--button').click
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
	$browser.button(:class => 'social-signin-google').click
	
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



# For go
if Date.today.next_day($moreDays).strftime('%a') == $jsonFile["go"]["usual_day"] || Date.today.next_day($moreDaysBis).strftime('%a') == $jsonFile["go"]["usual_day"]
	
	connect_me ENV["GoogleEmail"], ENV["GooglePassword"], ENV["GooglePin"]
	
	sleep 5
	
	buyOne = buy_ticket $jsonFile["go"]["usual_from"], $jsonFile["go"]["usual_to"], $jsonFile["go"]["usual_departure_time_min"], $jsonFile["go"]["usual_departure_time_max"], $jsonFile["go"]["usual_day"]
	
	if $jsonFile["go"]["from_option"][0]
		$jsonFile["go"]["from_option"].each do |from|
			if buyOne == false
				buyOne = buyOne = buy_ticket from, $jsonFile["go"]["usual_to"], $jsonFile["go"]["usual_departure_time_min"], $jsonFile["go"]["usual_departure_time_max"], $jsonFile["go"]["usual_day"]
			end
		end
	end
	
	if $jsonFile["go"]["to_option"][0]
		$jsonFile["go"]["to_option"].each do |to|
			if buyOne == false
				buyOne = buyOne = buy_ticket $jsonFile["go"]["usual_from"], to, $jsonFile["go"]["usual_departure_time_min"], $jsonFile["go"]["usual_departure_time_max"], $jsonFile["go"]["usual_day"]
			end
		end
	end
# For return
elsif Date.today.next_day($moreDays).strftime('%a') == $jsonFile["return"]["usual_day"] || Date.today.next_day($moreDaysBis).strftime('%a') == $jsonFile["return"]["usual_day"]
	
	connect_me ENV["GoogleEmail"], ENV["GooglePassword"], ENV["GooglePin"]
	
	sleep 5
	
	buyOne = buy_ticket $jsonFile["return"]["usual_from"], $jsonFile["return"]["usual_to"], $jsonFile["return"]["usual_departure_time_min"], $jsonFile["return"]["usual_departure_time_max"], $jsonFile["return"]["usual_day"]
	
	if $jsonFile["return"]["from_option"][0]
		$jsonFile["return"]["from_option"].each do |from|
			if buyOne == false
				buyOne = buyOne = buy_ticket from, $jsonFile["return"]["usual_to"], $jsonFile["return"]["usual_departure_time_min"], $jsonFile["return"]["usual_departure_time_max"], $jsonFile["return"]["usual_day"]
			end
		end
	end
	
	if $jsonFile["return"]["to_option"][0]
		$jsonFile["return"]["to_option"].each do |to|
			if buyOne == false
				buyOne = buyOne = buy_ticket $jsonFile["return"]["usual_from"], to, $jsonFile["return"]["usual_departure_time_min"], $jsonFile["return"]["usual_departure_time_max"], $jsonFile["return"]["usual_day"]
			end
		end
	end

# For special trip
else 
	
	$jsonFile["special_trip"].each do |trip|
		if Date.today.next_day($moreDays).strftime('%Y-%m-%d') == trip["date"] || Date.today.next_day($moreDaysBis).strftime('%Y-%m-%d') == trip["date"]
			connect_me ENV["GoogleEmail"], ENV["GooglePassword"], ENV["GooglePin"]
			sleep 5
			buy_ticket trip["from"], trip["to"], trip["time_min"], trip["time_max"], trip["date"]
		end
	end
	
end

$browser.close
