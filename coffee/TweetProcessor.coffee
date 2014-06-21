# Created by sitin on 31.05.14.

'use strict'


#
# Dependencies
#
Promise = require 'bluebird'
{EventEmitter} = require 'events'
_ = require 'lodash'
Tweet = require './models/Tweet'
User = require './models/User'


#
# Listens to tweets from stream and imports them to OrientDB
#
class TweetProcessor extends EventEmitter
    constructor: (@db, @stream, @twitter) ->

    #
    # Starts tweet processing form stream
    #
    start: ->
        @stream.on 'tweet', @processTweet

    #
    # Prints amount of vertices
    #
    logNumberOfVertices: ->
        @db.select().from('V').all().then (vertices) ->
            console.log "Total amount of vertices is #{vertices.length}."
            vertices.length

    #
    # Maps from all tags in text
    #
    mapTagsIn: (text, cb) ->
        (text.match(/#[\w\d]+/g) || []).map cb


    #
    # Converts RID to string
    #
    ridToString: (rid) ->
        "##{rid.cluster}:#{rid.position}"

    #
    # Process tweets and load them to database
    #
    processTweet: (data) =>
        @insertOrGet(new Tweet(data))
        .then @_connectTweet(data)

    #
    # Returns function that connects light tweet model with data
    #
    _connectTweet: (data) =>
        (tweet) =>
            # Wait for every job to be done before report
            Promise.all([
                @saveUser(tweet, data.user)   # Save tweet's user
                @saveTags(tweet)              # Save related tags
                @saveInReplyTo(tweet)         # Save tweet replied to
            ]).then ->
                console.log tweet.createdAt
                tweet

    #
    # Inserts model or updates it
    #
    insertOrGet: (model) ->
        Promise.try =>
            @db.vertex.create model
        .then (record) ->
            return record
        , @_getOnInsertError

    #
    # Loads record in case of insertion error
    #
    _getOnInsertError: (error) =>
        ridExtractionPattern =
            /previously assigned to the record (#\d+:\d+)$/
        matches = error.message.match ridExtractionPattern
        @db.record.get matches[1]

    #
    # Saves and connects to pair vertex
    #
    saveAndConnect: (model, pair, direction = '<-', edgeClass = 'E') =>
        record = null

        @insertOrGet model
        # Retrieve user RID in OrientDB format
        .then (_rec) =>
            record = _rec
            @connect _rec, pair, direction, edgeClass
        # Emit edge and return tag to be resolved as promise
        .then ->
            record

    #
    # Connects two vertices
    #
    connect: (v1, v2, direction = '<-', edgeClass = 'E') =>
        v1Rid = @ridToString v1['@rid']
        v2Rid = @ridToString v2['@rid']

        if direction == '<-'
            [vOut, vIn] = [v2Rid, v1Rid]
        else if direction == '->'
            [vOut, vIn] = [v1Rid, v2Rid]
        @db.edge.from(vOut).to(vIn).create '@class': edgeClass

    #
    # Processes tweet tags and loads them to database
    #
    saveTags: (tweet) ->
        # Loop over all tags in tweet
        Promise.all(@mapTagsIn tweet.text, (tagName) =>
            @saveAndConnect({'@class': 'VTag', name: tagName}, tweet)
            .then -> tagName
        )

    #
    # Saves tweet's user info
    #
    saveUser: (tweet, userData) ->
        @saveAndConnect(new User(userData), tweet, '->', 'EWrites')
        .then (user) ->
            user.id

    #
    # Saves replied to tweet
    #
    saveInReplyTo: (fromTweet) =>
        defer = Promise.defer()

        # Load and process tweet if fromTweet is replied to
        if fromTweet.inReplyTo and fromTweet.inReplyTo.statusIdStr
            handler = (err, data) =>
                toTweet = null
                unless err
                    @processTweet(data)
                    .then (_toTweet) =>
                        toTweet = _toTweet
                        @connect fromTweet, toTweet, '->', 'ERepliedTo'
                    .then ->
                        defer.resolve toTweet
                else
                    defer.reject err
            @twitter.get "statuses/show/:id",
                id: fromTweet.inReplyTo.statusIdStr,
                handler
        else
            defer.resolve null

        # Return promise
        defer.promise

# The only thing that we export is the tweet processor class itself
module.exports = TweetProcessor