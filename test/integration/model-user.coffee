assert = require('chai').assert

describe 'Integration: User', ->
  DatabaseHelper = require '../helpers/DatabaseHelper'
  User = require '../../app/models/User'
  Token = require '../../app/models/Token'
  
  beforeEach (done) ->
    DatabaseHelper.connect ->
      DatabaseHelper.empty User, Token, done
  
  afterEach (done) ->
    DatabaseHelper.disconnect done
  
  describe 'email uniqueness', ->
    it 'should allow multiple users with distinct email addresses', (done) ->
      user1 = new User email: 'test@test.com', password: 'test1234'
      user2 = new User email: 'foo@example.com', password: 'test1234'
      user1.save (err) ->
        assert.isNull err, 'valid user produces no error'
        user2.save (err) ->
          assert.isNull err, 'valid user produces no error'
          done()
    it 'should allow only one user with a given email address', (done) ->
      user1 = new User email: 'test@test.com', password: 'test1234'
      user2 = new User email: 'test@test.com', password: 'test1234'
      user1.save (err) ->
        throw err if err
        user2.save (err) ->
          assert.isDefined err.err
          assert.equal user1.email, user2.email, 'user emails are duplicates'
          done()
  
  describe 'revokeToken', ->
    it 'should do nothing if user has no token', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      assert.isUndefined user.token, 'user has no token'
      user.revokeToken (err, token) ->
        throw err if err
        assert.isUndefined token, 'revoke token returned no token'
        assert.isUndefined user.token, 'user still has no token'
        done()
    it 'should mark an existing user token as revoked', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err, token) ->
        throw err if err
        assert.equal token.revoked, false, 'token is unrevoked'
        user.revokeToken (err, token) ->
          throw err if err
          assert.equal user.token, token, 'user token and returned token are the same'
          assert.equal token.revoked, true, 'token is revoked'
          done()
    it 'should save an existing user token', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err, token) ->
        throw err if err
        user.revokeToken (err, token) ->
          throw err if err
          assert.equal token.isNew, false, 'revoked token is not new'
          assert.equal token.isModified(), false, 'revoked token has no unsaved changes'
          done()
  
  describe 'issueToken', ->
    it 'should assign and save a new token to the user', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err, token) ->
        throw err if err
        assert.instanceOf token, Token, 'new token is an instance of Token'
        assert.equal token.isNew, false, 'token is not new'
        assert.equal token.isModified(), false, 'token has no unsaved changes'
        user.populate 'token', (err) ->
          assert.equal user.token.id, token.id, 'user token ID is equal to token ID returned by issueToken'
          done()
    it 'should generate a token with no token_string', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err, token) ->
        throw err if err
        assert.isUndefined token.token_string, 'token_string on token is undefined'
        done()
    it 'should pass the raw token string as a parameter to the callback', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err, token, oldToken, tokenString) ->
        throw err if err
        assert.isString tokenString, 'token string is a string'
        done()
    it 'should revoke, save, and return an existing user token', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err, firstToken) ->
        throw err if err
        user.issueToken (err, secondToken, oldToken) ->
          throw err if err
          assert.equal firstToken.id, oldToken.id, 'first issued token is the same as old token'
          assert.equal oldToken.revoked, true, 'old token is revoked'
          assert.equal oldToken.isNew, false, 'old token is not new'
          assert.equal oldToken.isModified(), false, 'old token has no unsaved changes'
          done()
  
  describe 'compareToken', ->
    it 'should not match when user has no token', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.compareToken null, 'random12345', (err, isMatch) ->
        throw err if err
        assert.equal isMatch, false, 'candidate token does not match'
        done()
    it 'should not match when candidate token does not match user token hash', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err) ->
        throw err if err
        user.compareToken null, 'random12345', (err, isMatch) ->
          throw err if err
          assert.equal isMatch, false, 'candidate token does not match'
          done()
    it 'should match when candidate token matches user token hash', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err, token, oldToken, tokenString) ->
        throw err if err
        tokenId = token._id
        user.compareToken tokenId, tokenString, (err, isMatch) ->
          throw err if err
          assert.equal isMatch, true, 'candidate token matches'
          done()
  
  describe 'findByToken', ->
    it 'should return a user matching a raw token string', (done) ->
      user1 = new User email: 'test@test.com', password: 'test1234'
      user2 = new User email: 'foo@example.com', password: 'test1234'
      user1.issueToken (err, token, oldToken, tokenString) ->
        throw err if err
        user1TokenId = token._id
        user1TokenString = tokenString
        user2.issueToken (err, token, oldToken, tokenString) ->
          throw err if err
          user2TokenId = token._id
          user2TokenString = tokenString
          User.findByToken user1TokenId, user1TokenString, (err, user) ->
            assert.equal user.id, user1.id, 'user was correctly found by token'
            User.findByToken user2TokenId, user2TokenString, (err, user) ->
              assert.equal user.id, user2.id, 'user was correctly found by token'
              done()
    it 'should not return any user when no match is found', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.issueToken (err) ->
        throw err if err
        User.findByToken null, 'nosuchtokenstring', (err, user) ->
          assert.isUndefined user, 'no matching user was found'
          done()
