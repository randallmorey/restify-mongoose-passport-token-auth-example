assert = require('chai').assert

describe 'Integration: User', ->
  DatabaseHelper = require '../helpers/DatabaseHelper'
  User = require '../../app/models/User'
  Token = require '../../app/models/Token'
  
  beforeEach (done) ->
    DatabaseHelper.clearDatabase done
  
  after (done) ->
    DatabaseHelper.clearDatabase done
  
  describe 'revokeToken', ->
    it 'should do nothing if user has no token', (done) ->
      user = new User
      assert.isUndefined user.token, 'user has no token'
      user.revokeToken (err, token) ->
        throw err if err
        assert.isUndefined token, 'revoke token returned no token'
        assert.isUndefined user.token, 'user still has no token'
        done()
    it 'should mark an existing user token as revoked', (done) ->
      user = new User
      user.issueToken (err, token) ->
        throw err if err
        assert.equal token.revoked, false, 'token is unrevoked'
        user.revokeToken (err, token) ->
          throw err if err
          assert.equal user.token, token, 'user token and returned token are the same'
          assert.equal token.revoked, true, 'token is revoked'
          done()
    it 'should save an existing user token', (done) ->
      user = new User
      user.issueToken (err, token) ->
        throw err if err
        user.revokeToken (err, token) ->
          throw err if err
          assert.equal token.isNew, false, 'revoked token is not new'
          assert.equal token.isModified(), false, 'revoked token has no unsaved changes'
          done()
  
  describe 'issueToken', ->
    it 'should assign and save a new token to the user', (done) ->
      user = new User
      user.issueToken (err, token) ->
        throw err if err
        assert.instanceOf token, Token, 'new token is an instance of Token'
        assert.equal token.isNew, false, 'token is not new'
        assert.equal token.isModified(), false, 'token has no unsaved changes'
        user.populate 'token', (err) ->
          assert.equal user.token.id, token.id, 'user token ID is equal to token ID returned by issueToken'
          done()
    it 'should revoke, save, and return an existing user token', (done) ->
      user = new User
      user.issueToken (err, firstToken) ->
        throw err if err
        user.issueToken (err, secondToken, oldToken) ->
          throw err if err
          assert.equal firstToken.id, oldToken.id, 'first issued token is the same as old token'
          assert.equal oldToken.revoked, true, 'old token is revoked'
          assert.equal oldToken.isNew, false, 'old token is not new'
          assert.equal oldToken.isModified(), false, 'old token has no unsaved changes'
          done()
