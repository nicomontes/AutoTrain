# Introduction

With AutoTrain you can book your train tickets automatically on Trainline with TGVmax subscriptions.
TGVmax open booking 30 days before departure, this script allows you to sleep at midnight and buys your tickets as soon as possible.

# Installation

AutoTrain use [Watir](https://watir.com) and Google Chrome to browse Trainline website.

## Install Ruby

```bash
sudo apt-get install ruby  # for Ubuntu / Debian users
sudo yum install ruby      # for Red Hat / Fedora users

sudo apt-get install rubygems # for Ubuntu / Debian users
sudo yum install rubygems  # for Red Hat / Fedora users
```

## Install Watir and other gems

```bash
gem update --system --no-rdoc --no-ri
gem install watir --no-rdoc --no-ri

gem install rotp
gem install sendgrid-ruby
```

## Install Chrome Driver

You must to download Chrome driver [here](https://sites.google.com/a/chromium.org/chromedriver/downloads) and move in $PATH.

# Variables and Options

## Bash Variables

You must to export variables for authentication.  

* GOOGLE_EMAIL : Your Google Email
* GOOGLE_PASSWORD : Your password
* GOOGLE_PIN : Your Secret for OTP. To get this code you need to go to Google Preferences and change your phone.

Example :
```bash
export GoogleEmail='john.doe@gmail.com'; export GooglePassword='azerty123'; export GooglePin='9ea6lowvm7m57ltuwldrwqjkldjauhjz'
```

## Options

All options are in Json file.  

Exemple :
```json
{
  "go" : {
    "usual_from": "paris",
    "usual_to": "st-etienne",
    "from_option" : [],
    "to_option" : [
      "lyon",
      "annemasse"
    ],
    "usual_departure_time_min": "18:00",
    "usual_departure_time_max": "21:00",
    "usual_day": "Fri"
  },
  "return" : {
    "usual_from": "st-etienne",
    "usual_to": "paris",
    "from_option" : [
      "lyon"
    ],
    "to_option" : [],
    "usual_departure_time_min": "18:00",
    "usual_departure_time_max": "21:00",
    "usual_day": "Sun"
  },
  "special_trip": [
    {
      "date": "2017-04-22",
      "from": "paris",
      "to": "st-etienne",
      "time_min": "17:00",
      "time_max": "23:00"
    },
    {
      "date": "2017-02-19",
      "from": "paris",
      "to": "marseille",
      "time_min": "12:00",
      "time_max": "13:00"
    }
  ]
}
```

* The two sections *go* and *return* is used for the usual path.
  * *to_option* or *from_option* : City in options if Trainline don't find tickets for the usual departure or destination.
  * *usual_day* : week days in this format : (Mon, Tue, Wed, Thu, Fri, Sat, Sun).
* *special_trip* : You can add special_trip to go on holiday, for example !

# Use

```bash
ruby bookTrainline.rb
```

You can add this command in crontab to run at regular intervals.
