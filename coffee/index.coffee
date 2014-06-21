# Created by sitin on 31.05.14.

'use strict'


#
# Dependencies
#
Promise = require 'bluebird'
{EventEmitter} = require 'events'
_ = require 'lodash'
assert = require 'assert'
getOrientDb = require './db'
TweetProcessor = require './TweetProcessor'
{stream, twitter} = require './stream'


#
# The only thing that we export is the tweet processor
#
module.exports = tweetProcessor = ->
    getOrientDb('TagRelations').then (db) ->
        processor = new TweetProcessor db, stream, twitter
        processor.logNumberOfVertices()
        processor.start()

#
# Run if parent module
#
unless module.parent then tweetProcessor()