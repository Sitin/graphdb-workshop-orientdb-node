# Created by Mikhail Zyatin on 20.06.14.

'use strict'


{expect} = require 'chai'
graphdbWorkshopOrientdb = require '..'


describe 'graphdb-workshop-orientdb', ->
    it 'should be a function', ->
        expect(graphdbWorkshopOrientdb).to.be.a.function