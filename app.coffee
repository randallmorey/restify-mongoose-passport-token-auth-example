dotenv = require 'dotenv'
mongoose = require 'mongoose'
server = require './server'

dotenv.load()

connection = mongoose.connection
connection.on 'error',
  console.error.bind(console, 'connection error:')
connection.once 'open', ->
  mongodbUrl = "#{connection.host}:#{connection.port}/#{connection.name}"
  console.log "Connected to DB at #{mongodbUrl}"
mongoose.connect process.env.MONGODB_URL

server.listen process.env.RESTIFY_PORT, ->
  console.log "#{server.name} listening at #{server.url}"
