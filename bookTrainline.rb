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

# We can book a train 30 days before start
$moreDays = 30

puts Date.today.to_s + " + 30 days => " + Date.today.next_day($moreDays).to_s

# Method to buy ticket on trainline
def buy_ticket (from, to, timeMin, timeMax)
	# Go to search page
	$browser.goto "https://www.trainline.fr/search/"+from+"/"+to+"/"+Date.today.next_day($moreDays).to_s+"-"+timeMin.to_s+":00"
	
	# click on button search
	$browser.button(:class => 'button progress-button--button').click

	# Wait to load all trains
	sleep 10
	
	hours = $browser.spans(:class => 'time')
	hours.each do |h|
		trainHour = /[0-9]{1,2}h/.match(h.text.to_s).to_s
		trainHour = /[0-9]{1,2}/.match(trainHour).to_s
		trainMinute = /h[0-9]{1,2}/.match(h.text.to_s).to_s
		trainMinute = /[0-9]{1,2}/.match(trainMinute).to_s
		trainTime = trainHour.to_s+":"+trainMinute.to_s
		if Time.parse(trainTime) >= Time.parse(timeMin) && Time.parse(trainTime) <= Time.parse(timeMax)
			h.click
			sleep 2
			if $browser.button(:class => 'button progress-button--button').exist?
				$browser.button(:class => 'button progress-button--button').click
				sleep 10
				$browser.button(:class => 'button cart__button--pay').click
				sleep 5
				$browser.span(:class => 'ember-view checkbox checkbox--custom required').click
				sleep 2
				$browser.button(:type => 'submit').click
				puts "Pay ticket from "+from+" to "+to
				sleep 5
				return true
			end
		end
	end
	return false
end


# Method to connect me on trainline with Google account
def connect_me (account, password, pin)
	# Connect me
	$browser.button(:class => 'header__signin-button').click
	sleep 2
	if $browser.div(:class => 'form__errors').exist?
		sleep 5
	end
	$browser.button(:class => 'ember-view social-signin-google').click
	
	# Set Google account informations in popup windows
	$browser.window(:index => 1).use do
		$browser.text_field(:id => 'identifierId').set account
		$browser.div(:id => 'identifierNext').click

		$browser.text_field(:name => 'password').set password
		$browser.div(:id => 'passwordNext').click
		
		$totp = ROTP::TOTP.new(pin)
		
		$totpPin = $totp.now.to_s
		$browser.text_field(:id => 'totpPin').set $totpPin
		$browser.button(:id => 'submit').click
		sleep 5
	end	
end



# For go
if Date.today.next_day($moreDays).strftime('%a') == $jsonFile["go"]["usual_day"]
	
	connect_me ENV["GoogleEmail"], ENV["GooglePassword"], ENV["GooglePin"]
	
	sleep 5
	
	buyOne = buy_ticket $jsonFile["go"]["usual_from"], $jsonFile["go"]["usual_to"], $jsonFile["go"]["usual_departure_time_min"], $jsonFile["go"]["usual_departure_time_max"]
	
	if $jsonFile["go"]["from_option"][0]
		$jsonFile["go"]["from_option"].each do |from|
			if buyOne == false
				buyOne = buyOne = buy_ticket from, $jsonFile["go"]["usual_to"], $jsonFile["go"]["usual_departure_time_min"], $jsonFile["go"]["usual_departure_time_max"]
			end
		end
	end
	
	if $jsonFile["go"]["to_option"][0]
		$jsonFile["go"]["to_option"].each do |to|
			if buyOne == false
				buyOne = buyOne = buy_ticket $jsonFile["go"]["usual_from"], to, $jsonFile["go"]["usual_departure_time_min"], $jsonFile["go"]["usual_departure_time_max"]
			end
		end
	end
# For return
elsif Date.today.next_day($moreDays).strftime('%a') == $jsonFile["return"]["usual_day"]
	
	connect_me ENV["GoogleEmail"], ENV["GooglePassword"], ENV["GooglePin"]
	
	sleep 5
	
	buyOne = buy_ticket $jsonFile["return"]["usual_from"], $jsonFile["return"]["usual_to"], $jsonFile["return"]["usual_departure_time_min"], $jsonFile["return"]["usual_departure_time_max"]
	
	if $jsonFile["return"]["from_option"][0]
		$jsonFile["return"]["from_option"].each do |from|
			if buyOne == false
				buyOne = buyOne = buy_ticket from, $jsonFile["return"]["usual_to"], $jsonFile["return"]["usual_departure_time_min"], $jsonFile["return"]["usual_departure_time_max"]
			end
		end
	end
	
	if $jsonFile["return"]["to_option"][0]
		$jsonFile["return"]["to_option"].each do |to|
			if buyOne == false
				buyOne = buyOne = buy_ticket $jsonFile["return"]["usual_from"], to, $jsonFile["return"]["usual_departure_time_min"], $jsonFile["return"]["usual_departure_time_max"]
			end
		end
	end

# For special trip
else 
	
	$jsonFile["special_trip"].each do |trip|
		if Date.today.next_day($moreDays).strftime('%Y-%m-%d') == trip["date"]
			connect_me ENV["GoogleEmail"], ENV["GooglePassword"], ENV["GooglePin"]
			sleep 5
			buy_ticket trip["from"], trip["to"], trip["time_min"], trip["time_max"]
		end
	end
	
end

$browser.close
