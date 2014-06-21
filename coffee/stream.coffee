# Created by Mikhail Zyatin on 20.06.14.

'use strict'


# Setup Twitter
Twitter = require 'twit'
twitter = new Twitter require './../config/.twitter-auth.json'

# Stream query
condition = track: '#WorldCup'
#condition = location: require('./../config/locations.json').Ukraine

# Export stream
module.exports.twitter = twitter
module.exports.stream= twitter.stream 'statuses/filter', condition