restify = require 'restify'

app = restify.createServer()
app.listen 3000, ->
  console.log '%s listening at %s', app.name, app.url
