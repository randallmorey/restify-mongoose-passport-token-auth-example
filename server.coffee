_ = require 'underscore'
restify = require 'restify'
passport = require 'passport'
basicAuthStrategy = require './app/auth-strategies/basic'
User = require './app/models/User'

passport.use basicAuthStrategy

server = restify.createServer()
server
  .use restify.fullResponse()
  .use restify.bodyParser()
  .use passport.initialize()

# /auth/login
server.post '/auth/token',
  passport.authenticate('basic', session: false),
  (req, res, next) ->
    res.send 201, {token_string: req.user.token_string}

# /users
server.post '/users', (req, res, next) ->
  email = req.params.email
  password = req.params.password
  if email and password
    user = new User
      email: email
      password: password
    user.save (err) ->
      if err?.code == 11000
        next new restify.InvalidArgumentError 'Email is already taken.'
      if err?.name == 'ValidationError'
        message = _.chain(err.errors).pairs().first().last().value().message
        next new restify.InvalidArgumentError message
      else if err
        next err
      else
        res.send 201, user
  else
    next new restify.InvalidArgumentError 'Email and password required.'

module.exports = server
