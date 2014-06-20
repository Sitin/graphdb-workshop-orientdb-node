# Created by Mikhail Zyatin on 20.06.14.

'use strict'


# Setup Twitter
Twitter = require 'twit'
twitter = new Twitter require './../config/.twitter-auth.json'

# Export stream
module.exports = twitter.stream 'statuses/filter', track: '#apple'