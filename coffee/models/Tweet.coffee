# Created by Mikhail Zyatin on 20.06.14.

'use strict'


_ = require 'lodash'
moment = require 'moment'
changeCase = require 'change-case'


#
# A Tweet model class
#
class Tweet
    #
    # Imports data into instance
    #
    constructor: (data) ->
        # Construct Tweet model
        @['@class'] = 'VTweet'
        @text = data.text
        @createdAt =
            moment.utc(new Date data.created_at).format 'YYYY-MM-DD HH:mm:ss'
        @inReplyTo = getInReplyTo data
        @data = _.omit data, isExcludedTweetField


# The only thing to export is a class itself
module.exports = Tweet


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
# Returns true if field should be excluded from tweet model
#
isExcludedTweetField = (key) ->
    ['user', 'created_at', 'text']
    .indexOf(key) > -1 or isInReplyTo key

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