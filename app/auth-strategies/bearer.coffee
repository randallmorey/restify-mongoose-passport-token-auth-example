BearerStrategy = require('passport-http-bearer').Strategy
User = require '../models/User'

module.exports = new BearerStrategy passReqToCallback: true,
  (req, tokenString, done) ->
    decodedTokenString = new Buffer(tokenString, 'base64').toString()
    User.findByToken decodedTokenString, (err, user) ->
      return done null, false, message: 'Invalid token' if !user
      done null, user
