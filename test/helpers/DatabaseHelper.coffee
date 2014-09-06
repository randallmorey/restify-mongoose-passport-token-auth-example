dotenv = require 'dotenv'
mongoose = require 'mongoose'

dotenv.load()

class DatabaseHelper
  @_clearDatabase: (next) ->
    collections = (name for name of mongoose.connection.collections)
    removeOrNext = ->
      if collections.length
        mongoose.connection.db.dropCollection collections.pop(), ->
          removeOrNext()
      else
        next()
    removeOrNext()
  
  @_connect: (next) ->
    mongoose.connect process.env.MONGODB_URL, (err) =>
      throw err if err
      next()
  
  @clearDatabase: (next) ->
    if mongoose.connection.readyState == 0
      @_connect => @_clearDatabase next
    else
      @_clearDatabase next

module.exports = DatabaseHelper
