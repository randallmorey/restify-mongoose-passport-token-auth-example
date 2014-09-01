dotenv = require 'dotenv'
restify = require 'restify'

dotenv.load()

app = restify.createServer()
app.listen process.env.RESTIFY_PORT, ->
  console.log '%s listening at %s', app.name, app.url
