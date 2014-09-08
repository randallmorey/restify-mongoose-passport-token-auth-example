dotenv = require 'dotenv'
mongoose = require 'mongoose'

dotenv.load()

class DatabaseHelper
  @connect: (next) ->
    if mongoose.connection.readyState == 0
      mongoose.connect process.env.MONGODB_URL, (err) =>
        throw err if err
        next()
    else
      next()
  
  @disconnect: (next) ->
    mongoose.disconnect next
  
  @clearDatabase: (next) ->
    collections = (name for name of mongoose.connection.collections)
    removeOrNext = ->
      if collections.length
        mongoose.connection.db.dropCollection collections.pop(), ->
          removeOrNext()
      else
        next()
    removeOrNext()

module.exports = DatabaseHelper
