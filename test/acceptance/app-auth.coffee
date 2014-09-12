supertest = require 'supertest'

describe 'Acceptance: Auth', ->
  app = require '../../server.coffee'
  DatabaseHelper = require '../helpers/DatabaseHelper'
  Token = require '../../app/models/Token'
  User = require '../../app/models/User'
  userData =
    email: 'test@test.com'
    password: 'test1234'
  invalidUserData =
    email: 'test@test.com'
    password: 'wrongpassword'
  nonExistentUserDate =
    email: 'foo@bar.com'
    password: 'nosuchuser'
  user = null
  basicAuthHeader = [
    'Basic'
    new Buffer("#{userData.email}:#{userData.password}").toString 'base64'
  ].join ' '
  basicAuthInvalidHeader = [
    'Basic'
    new Buffer("#{invalidUserData.email}:#{invalidUserData.password}").toString 'base64'
  ].join ' '
  basicAuthNonExistentHeader = [
    'Basic'
    new Buffer("#{nonExistentUserDate.email}:#{nonExistentUserDate.password}").toString 'base64'
  ].join ' '
  
  beforeEach (done) ->
    DatabaseHelper.connect ->
      DatabaseHelper.empty User, Token, ->
        User.create userData, (err, instance) ->
          user = instance
          done err
  
  afterEach (done) ->
    DatabaseHelper.disconnect done
  
  describe '/auth/token', ->
    describe 'POST', ->
      it 'should create and return a new user token [201]', (done) ->
        supertest app
          .post '/auth/token'
          .set 'Authorization', basicAuthHeader
          .send()
          .expect 201
          .expect (res) ->
            'token_string was not present in response' if !res.body.token_string
          .end done
      it 'should create a token that matches the assigned user token [201]', (done) ->
        supertest app
          .post '/auth/token'
          .set 'Authorization', basicAuthHeader
          .send()
          .expect 201
          .end (err, res) ->
            throw err if err
            User.find (err, users) ->
              throw err if err
              users[0].compareToken res.body.token_string, (err, isMatch) ->
                throw new Error 'response token does not match assigned user token' if !isMatch
                done err
      it 'should revoke a previously assigned user token and return a new one [201]', (done) ->
        supertest app
          .post '/auth/token'
          .set 'Authorization', basicAuthHeader
          .send()
          .expect 201
          .end (err, res) ->
            throw err if err
            oldTokenString = res.body.token_string
            supertest app
              .post '/auth/token'
              .set 'Authorization', basicAuthHeader
              .send()
              .expect 201
              .end (err, res) ->
                throw err if err
                newTokenString = res.body.token_string
                throw new Error 'old and new token strings match' if oldTokenString == newTokenString
                User.find (err, users) ->
                  throw err if err
                  users[0].compareToken newTokenString, (err, isMatch) ->
                    throw err if err
                    throw new Error 'response token does not match assigned user token' if !isMatch
                    users[0].compareToken oldTokenString, (err, isMatch) ->
                      throw err if err
                      throw new Error 'old token matches assigned user token, but should not' if isMatch
                      Token.find (err, tokens) ->
                        throw new Error 'old token was not revoked' if !tokens[0].revoked
                        done err
      it 'should fail when invalid password is passed [401]', (done) ->
        supertest app
          .post '/auth/token'
          .set 'Authorization', basicAuthInvalidHeader
          .send()
          .expect 401
          .end done
      it 'should fail when user does not exist [401]', (done) ->
        supertest app
          .post '/auth/token'
          .set 'Authorization', basicAuthNonExistentHeader
          .send()
          .expect 401
          .end done
    
    describe 'DELETE', ->
      it 'should revoke the matched user token [204]', (done) ->
        user.issueToken (err, token, oldToken, tokenString) ->
          bearerAuthHeader = [
            'Bearer'
            new Buffer("#{tokenString}").toString('base64')
          ].join ' '
          throw new Error 'user token not issued' if !token or !tokenString
          supertest app
            .delete '/auth/token'
            .set 'Authorization', bearerAuthHeader
            .send()
            .expect 204
            .end (err, res) ->
              throw err if err
              user.populate 'token', (err) ->
                throw new Error 'user token not revoked' if !user.token.revoked
                done err
      it 'should fail when no token is passed [401]', (done) ->
        supertest app
          .post '/auth/token'
          .set 'Authorization', 'Bearer '
          .send()
          .expect 401
          .end done
      it 'should fail when invalid token is passed [401]', (done) ->
        supertest app
          .post '/auth/token'
          .set 'Authorization', 'Bearer nosuchtoken'
          .send()
          .expect 401
          .end done
