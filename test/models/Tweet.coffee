# Created by Mikhail Zyatin on 20.06.14.

'use strict'


{expect} = require 'chai'
Tweet = require '../../lib/models/Tweet'


describe 'Tweet', ->
    # Simple tweet
    tweet = new Tweet
        in_reply_to_spam: 'Spam'
        text: 'Spam! Spam!'
        user: 'Nobody'
        created_at: 'Fri Jun 20 13:13:32 +0000 2014'
        spam: 'Spam'

    it 'Should be a constructor function', ->
        expect(Tweet).to.be.a.function

    it 'Should add a @class property', ->
        expect(tweet).to.have.a.property '@class', 'VTweet'

    it 'Should import `text` property', ->
        expect(tweet).to.have.a.property 'text', 'Spam! Spam!'

    it 'Should format datetime of creation', ->
        expect(tweet).to.have.a.property 'createdAt', '2014-06-20 13:13:32'

    it 'Should embed "in reply to" fields if existed', ->
        expect(tweet).to.have.a.property 'inReplyTo'
        expect(tweet.inReplyTo).to.have.a.property 'spam', 'Spam'
        expect(tweet).to.have.not.property 'in_reply_to_spam'

    it 'Should attach data with all unprocessed attributes', ->
        expect(tweet.data).to.have.a.property 'spam', 'Spam'
        for key of ['created_at', 'user', 'text', 'in_reply_to_spam']
            expect(tweet.data).to.have.not.property key
