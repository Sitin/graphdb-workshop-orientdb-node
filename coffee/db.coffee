# Created by sitin on 20.06.14.

'use strict'


oriento = require 'oriento'
Promise = require 'bluebird'


# List databases and resolve TagRelations
module.exports = (dbName) ->
    # Configure server instance
    server = oriento require './../config/.orientdb-connection.json'

    # Database promise that will be resolved after server inspection
    database = Promise.defer()

    # List databases and resolve desired
    server.list()
    .then (dbs) ->
        console.log "There are #{dbs.length} databases on the server:"
        dbs.forEach (db, i) ->
            console.log "Database No #{i + 1} - #{db.name}"
            if db.name == dbName then process.nextTick ->
                database.resolve db

    # Here we are:
    database.promise