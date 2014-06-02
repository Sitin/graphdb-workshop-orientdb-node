# Created by sitin on 31.05.14.


Oriento = require 'oriento'
Promise = require 'bluebird'
Twitter = require 'twit'
{EventEmitter} = require 'events'
moment = require 'moment'
_ = require 'lodash'
changeCase = require 'change-case'

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
# Converts data to Twitter model class
#
getTweetModelFromData = (data) ->
  # Construct Tweet model
  '@class': 'VTweet'
  text:       data.text
  createdAt:  moment.utc(new Date data.created_at).format 'YYYY-MM-DD HH:mm:ss'
  user:       data.user
  inReplyTo:  getInReplyTo data
  data:       _.omit data, isExcludedTweetField


# Play with database
database.promise.then (db) ->
  # Show amount of vertices
  db.select().from('V').all().then (vertices) ->
    console.log "Total amount of vertices is #{vertices.length}."

  # Setup Twitter
  twitter = new Twitter require './.twitter-auth.json'
  stream = twitter.stream 'statuses/filter', track: '#apple'

  # Specify index
  tagsIndex = db.index.get('VTag.name')

  # Create event responder
  events = new EventEmitter

  #
  # Process tweets and load them to database
  #
  stream.on 'tweet', (data) ->
    db.vertex.create(getTweetModelFromData(data))
    .then (tweet) ->
      # Report tweet saving
      events.emit 'tweet', tweet
      # Save related tags
      saveTags(tweet).then (tags) ->
        events.emit 'tweet and tags', tweet: tweet, tags: tags

  #
  # Processes tweet tags and loads them to database
  #
  saveTags = (tweet) ->
    tweetRid = ridToString tweet['@rid']

    # Loop over all tags in tweet
    Promise.all (mapTagsIn tweet.text, (tagName) ->
      # Find tag key by name in unique index
      tagsIndex.then (tagsIndex) ->
        tagsIndex.get tagName
      # Create or load tag form database
      .then (tag) ->
        if (!tag) then db.vertex.create '@class': 'VTag', name: tagName
        else db.record.get ridToString tag.rid
      # Retrieve tag RID in OrientDB format
      .then (tag) ->
        events.emit 'tag', tag
        ridToString(tag['@rid'] || tag.rid)
      # Create edge from tweet to tag
      .then (tagRid) ->
        db.edge.from(tweetRid).to(tagRid).create '@class': 'E'
      # Emit edge and return tag to be resolved as promise
      .then (edge) ->
        events.emit 'tag to tweet', edge
        tagName
    )

  #
  # Report about tags and tweet saving
  #
  events.on 'tag to tweet', ->
    console.log '.'