BearerStrategy = require('passport-http-bearer').Strategy
User = require '../models/User'

module.exports = new BearerStrategy passReqToCallback: true,
  (req, tokenString, done) ->
    decodedToken = new Buffer(tokenString, 'base64').toString().split ':'
    tokenId = decodedToken[0]
    token = decodedToken[1]
    User.findByToken token, (err, user) ->
      return done null, false, message: 'Invalid token' if !user
      done null, user
