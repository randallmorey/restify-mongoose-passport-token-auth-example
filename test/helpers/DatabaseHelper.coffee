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
  
  @empty: (models..., next) ->
    removeOrNext = ->
      if models.length
        models.pop().remove (err) ->
          return next err if err
          removeOrNext()
      else
        next()
    removeOrNext()

module.exports = DatabaseHelper
