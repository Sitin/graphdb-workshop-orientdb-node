# Created by sitin on 31.05.14.


Oriento = require 'oriento'
Promise = require 'bluebird'
Twitter = require 'twit'
{EventEmitter} = require 'events'
moment = require 'moment'
_ = require 'lodash'
changeCase = require 'change-case'
assert = require 'assert'

# Configure server instance
server = Oriento require './.orientdb-connection.json'

# Database promise that will be resolved after server inspection
database = Promise.defer()

# Database name
dbName = 'TagRelations'


# List databases and resolve TagRelations
server.list()
  .then (dbs) ->
    console.log "There are #{dbs.length} databases on the server:"
    dbs.forEach (db, i) ->
      console.log "Database No #{i+1} - #{db.name}"
      if db.name == dbName then process.nextTick ->
        database.resolve db


#
# Maps from all tags in text
#
mapTagsIn = (text, cb) ->
  (text.match(/#[\w\d]+/g) || []).map cb


#
# Converts RID to string
#
ridToString = (rid) ->
  "##{rid.cluster}:#{rid.position}"


#
# Strip 'in_reply_to_' and convert to camelCase
#
transformInReplyKey = (key) ->
  changeCase.camelCase key.replace 'in_reply_to_', ''


#
# Tests whether this is a in reply to field
#
isInReplyTo = (key) ->
  /^in_reply_to_/.test key


#
# Returns hash with in_reply_to fields
#
getInReplyTo = (data) ->
  result = {}
  _.forOwn data, (value, key) ->
    if isInReplyTo key
      result[transformInReplyKey key] = value
  # Return null instead of object of nulls
  if _.every(result, (value) -> value is null)
    result = null
  # Return value
  result


#
# Returns true if field should be excluded from tweet model
#
isExcludedTweetField = (key) ->
  ['user', 'created_at', 'text'].indexOf(key) > -1 or isInReplyTo key


#
# Converts data to Twitter model object
#
tweetModel = (data) ->
  # Construct Tweet model
  '@class': 'VTweet'
  text:       data.text
  createdAt:  moment.utc(new Date data.created_at).format 'YYYY-MM-DD HH:mm:ss'
  inReplyTo:  getInReplyTo data
  data:       _.omit data, isExcludedTweetField


#
# Converts data to Twitter user model object
#
# assert.deepEqual {'@class': 'VUser', aA: 1, bB: 2}, userModel {a_a: 1, b_b: 2}
#
userModel = (data) ->
  camelCased = _.zipObject ([changeCase.camelCase(key), value] for key, value of data)
  _.merge {'@class': 'VUser'}, camelCased


# Play with database
database.promise.then (db) ->
  # Show amount of vertices
  db.select().from('V').all().then (vertices) ->
    console.log "Total amount of vertices is #{vertices.length}."

  # Setup Twitter
  twitter = new Twitter require './.twitter-auth.json'
  stream = twitter.stream 'statuses/filter', track: '#apple'

  # Create event responder
  events = new EventEmitter

  #
  # Process tweets and load them to database
  #
  stream.on 'tweet', (data) ->
    db.vertex.create(tweetModel(data))
    .then (tweet) ->
      # Whait for every job to be done before report
      Promise.all([
        saveUser(tweet, data.user) # Save tweet's user
        saveTags(tweet)            # Save related tags
      ]).then (results) ->
        # Report tweet saving
        events.emit 'everything for tweet', results

  #
  # Inserts model or updates it
  #
  insertOrGet = (model) ->
    Promise.try ->
      db.vertex.create model
    .then (record) ->
      return record
    , (error) ->
      matches = error.message.match /previously assigned to the record (#\d+:\d+)$/
      db.record.get matches[1]

  #
  # Saves and connects to pair vertex
  #
  saveAndConnect = (model, pair, direction='<-', edgeClass='E') ->
    pairRid = ridToString pair['@rid']
    record = null

    insertOrGet model
    # Retrieve user RID in OrientDB format
    .then (_rec) ->
      record = _rec
      events.emit record['@class'], record
      ridToString(record['@rid'] || record.rid)
    # Create edge from tweet to tag
    .then (recordRid) ->
      if direction == '<-'
        [vOut, vIn] = [pairRid, recordRid]
      else if direction == '->'
        [vOut, vIn] = [recordRid, pairRid]
      db.edge.from(vOut).to(vIn).create '@class': edgeClass
    # Emit edge and return tag to be resolved as promise
    .then (edge) ->
      events.emit "#{record['@class']} -- #{pair['@class']}", edge
      record

  #
  # Processes tweet tags and loads them to database
  #
  saveTags = (tweet) ->
    # Loop over all tags in tweet
    Promise.all(mapTagsIn tweet.text, (tagName) ->
      saveAndConnect({'@class': 'VTag', name: tagName}, tweet)
      .then -> tagName
    )

  #
  # Saves tweet's user info
  #
  saveUser = (tweet, userData) ->
    saveAndConnect(userModel(userData), tweet, '->')
    .then (user) -> user.id

  #
  # Report about tags and tweet saving
  #
  events.on 'everything for tweet', ->
    console.log '.'