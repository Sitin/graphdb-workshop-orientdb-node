# Created by Mikhail Zyatin on 20.06.14.

'use strict'


{expect} = require 'chai'
User = require '../../lib/models/User'


describe 'User', ->
    it 'Should be a constructor function', ->
        expect(User).to.be.a.function


    it 'Should add a @class property', ->
        expect(new User {}).to.have.a.property '@class', 'VUser'


    it 'Should camelCase all properties', ->
        expect(new User {under_scored: 'Spam'})
            .to.have.a.property 'underScored', 'Spam'
