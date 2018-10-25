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
* SENDGRID_API_KEY : SendGrid API to send emails

Example :
```bash
export GoogleEmail='john.doe@gmail.com'; export GooglePassword='azerty123'; export GooglePin='9ea6lowvm7m57ltuwldrwqjkldjauhjz'; export SENDGRID_API_KEY="SG.ZxoW78maTraWvtR_zS93IklGh6Hy.i6GH66_dFVbtS0DPaALCdXDgVLySsfhfMjru38"
```

## Options

All options are in Json file.  

Exemple :
```json
{
  "trip" : [
    {
      "from": "paris",
      "to": "st-etienne",
      "time_min": "16:00",
      "time_max": "19:00",
      "day": "Fri",
      "trip" :
        {
          "from": "paris",
          "to": "lyon",
          "time_min": "16:00",
          "time_max": "19:00",
          "day": "Fri",
          "trip" :
            {
              "from": "paris",
              "to": "le-creusot-tgv",
              "time_min": "16:00",
              "time_max": "18:00",
              "day": "Fri"
            }
        }
    },
    {
      "from": "st-etienne",
      "to": "paris",
      "time_min": "17:00",
      "time_max": "19:00",
      "day": "Sun",
      "trip" :
        {
          "from": "lyon",
          "to": "paris",
          "time_min": "18:00",
          "time_max": "20:00",
          "day": "Sun",
          "trip" :
            {
              "from": "le-creusot-tgv",
              "to": "paris",
              "time_min": "18:00",
              "time_max": "21:30",
              "day": "Sun",
              "trip" :
                {
                  "from": "st-etienne",
                  "to": "paris",
                  "time_min": "06:00",
                  "time_max": "07:00",
                  "day": "Mon"
                }
            }
        }
    }
  ],
  "special_trip" : [
    {
      "date": "2018-03-28",
      "from": "paris",
      "to": "lille",
      "time_min": "12:00",
      "time_max": "14:00"
    },
    {
      "date": "2017-08-08",
      "from": "st-etienne",
      "to": "paris",
      "time_min": "16:00",
      "time_max": "23:00"
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
