BasicStrategy = require('passport-http').BasicStrategy
User = require '../models/User'

module.exports = new BasicStrategy passReqToCallback: true,
  (req, email, password, done) ->
    User.findOne email: email,
      (err, user) ->
        return done null, false, message: 'Invalid credentials' if !user
        user.comparePassword password, (err, isMatch) ->
          return done err if err
          if isMatch
            user.issueToken (err, token, oldToken, tokenString) ->
              return done err if err
              user = user.toJSON()
              token = token.toJSON()
              token.token_string = tokenString
              user.token = token
              done null, user
          else
            done null, false, message: 'Invalid credentials'
