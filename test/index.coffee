{expect} = require 'chai'
graphdbWorkshopOrientdb = require '..'

describe 'graphdb-workshop-orientdb', ->
    it 'should say hello', (done) ->
        expect(graphdbWorkshopOrientdb()).to.be.a.function
        done()