supertest = require 'supertest'

describe 'Acceptance: Auth', ->
  app = require '../../server.coffee'
  DatabaseHelper = require '../helpers/DatabaseHelper'
  TokenHelper = require '../helpers/TokenHelper'
  Token = require '../../app/models/Token'
  User = require '../../app/models/User'
  userData =
    email: 'test@test.com'
    password: 'test1234'
  invalidUserData =
    email: 'test@test.com'
    password: 'wrongpassword'
  nonExistentUserData =
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
    new Buffer("#{nonExistentUserData.email}:#{nonExistentUserData.password}").toString 'base64'
  ].join ' '
  
  beforeEach (done) ->
    DatabaseHelper.connect ->
      DatabaseHelper.empty User, Token, ->
        User.create userData, (err, instance) ->
          user = instance
          done err
  
  afterEach (done) ->
    DatabaseHelper.disconnect done
  
  describe '/tokens', ->
    describe 'POST', ->
      it 'should create and return a new user token [201]', (done) ->
        supertest app
          .post '/tokens'
          .set 'Authorization', basicAuthHeader
          .send()
          .expect 201
          .expect (res) ->
            'token_string was not present in response' if !res.body.token_string
          .end done
      it 'should create a token that matches the assigned user token [201]', (done) ->
        supertest app
          .post '/tokens'
          .set 'Authorization', basicAuthHeader
          .send()
          .expect 201
          .end (err, res) ->
            throw err if err
            User.find (err, users) ->
              throw err if err
              decodedToken = TokenHelper.decodeTokenString res.body.token_string
              users[0].compareToken decodedToken.token_string, (err, isMatch) ->
                throw new Error 'response token does not match assigned user token' if !isMatch
                done err
      it 'should revoke a previously assigned user token and return a new one [201]', (done) ->
        supertest app
          .post '/tokens'
          .set 'Authorization', basicAuthHeader
          .send()
          .expect 201
          .end (err, res) ->
            throw err if err
            oldDecodedToken = TokenHelper.decodeTokenString res.body.token_string
            oldTokenString = res.body.token_string
            supertest app
              .post '/tokens'
              .set 'Authorization', basicAuthHeader
              .send()
              .expect 201
              .end (err, res) ->
                throw err if err
                newDecodedToken = TokenHelper.decodeTokenString res.body.token_string
                newTokenString = res.body.token_string
                throw new Error 'old and new token strings match' if oldTokenString == newTokenString
                User.find (err, users) ->
                  throw err if err
                  users[0].compareToken newDecodedToken.token_string, (err, isMatch) ->
                    throw err if err
                    throw new Error 'response token does not match assigned user token' if !isMatch
                    users[0].compareToken oldDecodedToken.token_string, (err, isMatch) ->
                      throw err if err
                      throw new Error 'old token matches assigned user token, but should not' if isMatch
                      Token.find (err, tokens) ->
                        throw new Error 'old token was not revoked' if !tokens[0].revoked
                        done err
      it 'should fail when invalid password is passed [401]', (done) ->
        supertest app
          .post '/tokens'
          .set 'Authorization', basicAuthInvalidHeader
          .send()
          .expect 401
          .end done
      it 'should fail when user does not exist [401]', (done) ->
        supertest app
          .post '/tokens'
          .set 'Authorization', basicAuthNonExistentHeader
          .send()
          .expect 401
          .end done
    
    describe 'DELETE', ->
      it 'should revoke the matched user token [204]', (done) ->
        user.issueToken (err, token, oldToken, tokenString) ->
          tokenId = token._id
          encodedToken = new Buffer([
            tokenId
            tokenString
          ].join ':').toString 'base64'
          bearerAuthHeader = [
            'Bearer'
            encodedToken
          ].join ' '
          throw new Error 'user token not issued' if !token or !tokenString
          supertest app
            .delete '/tokens'
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
          .post '/tokens'
          .set 'Authorization', 'Bearer '
          .send()
          .expect 401
          .end done
      it 'should fail when invalid token is passed [401]', (done) ->
        supertest app
          .post '/tokens'
          .set 'Authorization', 'Bearer nosuchtoken'
          .send()
          .expect 401
          .end done
