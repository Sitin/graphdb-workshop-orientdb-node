# Created by Mikhail Zyatin on 20.06.14.

'use strict'


_ = require 'lodash'
changeCase = require 'change-case'


#
# Converts data to Twitter user model object
#
# assert.deepEqual {'@class': 'VUser', aA: 1, bB: 2}, userModel {a_a: 1, b_b: 2}
#
class User
    constructor: (data) ->
        camelCased = _.zipObject(
            for key, value of data
                [changeCase.camelCase(key), value]
        )
        _.merge @, {'@class': 'VUser'}, camelCased


# Export class
module.exports = User