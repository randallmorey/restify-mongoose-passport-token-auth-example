dotenv = require 'dotenv'
assert = require('chai').assert

dotenv.load()

describe 'Unit: Token', ->
  Token = require '../../app/models/Token'
  tokenExpirationTimeout = parseInt process.env.TOKEN_EXPIRATION_TIMEOUT_MILLISECONDS, 10
  
  describe 'defaults', ->
    it 'should include a 256-character token_string', ->
      token = new Token
      assert.isString token.token_string, 'token_string is a string'
      assert.lengthOf token.token_string, 256, 'token_string is 256 characters'
    it 'should include a revoked boolean that defaults to false', ->
      token = new Token
      assert.equal token.revoked, false, 'token is not revoked by default'
    it 'should include a created_on date', ->
      token = new Token
      assert.instanceOf token.created_on, Date, 'created_on is an Date'
    it 'should include a expires_on date', ->
      token = new Token
      assert.instanceOf token.expires_on, Date, 'expires_on is an Date'
    it 'should include different created_on and expires_on dates', ->
      token = new Token
      assert.notEqual token.created_on, token.expires_on, 'created_on and expires_on have different values'
  
  describe 'validate', ->
    it 'should pass without specifying any values during instantiation', (done) ->
      token = new Token
      token.validate (err) ->
        assert.isUndefined err, 'valid token'
        done()
    it 'should fail on missing token_string by virtue of missing token_hash', (done) ->
      token = new Token token_string: null
      token.validate (err) ->
        assert.equal err.errors.token_hash.type, 'required', 'token_hash is required'
        done()
    it 'should fail on missing created_on', (done) ->
      token = new Token created_on: null
      token.validate (err) ->
        assert.equal err.errors.created_on.type, 'required', 'created_on is required'
        done()
    it 'should fail on missing expires_on', (done) ->
      token = new Token expires_on: null
      token.validate (err) ->
        assert.equal err.errors.expires_on.type, 'required', 'expires_on is required'
        done()
  
  describe 'token_string', ->
    it 'should not exist after successful validate', (done) ->
      token = new Token
      token.validate (err) ->
        assert.isUndefined err, 'validation successful'
        assert.isUndefined token.token_string, 'token_string does not exist'
        done()
    it 'should not exist after failed validate', (done) ->
      token = new Token created_on: null
      token.validate (err) ->
        assert.equal err.errors.created_on.type, 'required', 'created_on is required'
        assert.isUndefined token.token_string, 'token_string does not exist'
        done()
  
  describe 'token_hash', ->
    it 'should exist after validate', (done) ->
      token = new Token
      token.validate (err) ->
        assert.isString token.token_hash, 'token_hash exists'
        done()
  
  describe 'compareToken', ->
    it 'should match when token_string and token_hash match', (done) ->
      token = new Token
      token_string = token.token_string
      token.validate (err) ->
        token.compareToken null, token_string, (err, isMatch) ->
          throw err if err
          assert.equal isMatch, true, 'tokens match'
          done()
    it 'should not match when token_string and token_hash do not match', (done) ->
      token = new Token
      token_string = 'some random non-token string'
      token.validate (err) ->
        token.compareToken null, token_string, (err, isMatch) ->
          throw err if err
          assert.equal isMatch, false, 'tokens do not match'
          done()
  
  describe 'isExpired', ->
    it 'should return false before expires_on', ->
      token = new Token
      assert.ok token.expires_on.getTime() > Date.now(), 'expires_on is in the future'
      assert.equal token.isExpired(), false, 'isExpired returns false'
    it 'should return true after expires_on', (done) ->
      token = new Token
      assert.isDefined process.env.TOKEN_EXPIRATION_TIMEOUT_MILLISECONDS, 'TOKEN_EXPIRATION_TIMEOUT_MILLISECONDS environment variable is defined'
      assert.ok tokenExpirationTimeout < 2000, 'token expiration timeout is less than 2000 ms'
      setTimeout (->
        assert.ok token.expires_on.getTime() < Date.now(), 'expires_on is in the past'
        assert.equal token.isExpired(), true, 'isExpired returns true'
        done()
      ), tokenExpirationTimeout + 1
  
  describe 'isRevoked', ->
    it 'should return false when token is not revoked', ->
      token = new Token
      assert.equal token.revoked, false, 'token is not revoked'
      assert.equal token.isRevoked(), false, 'isRevoked returns false'
    it 'should return true when revoked is revoked', ->
      token = new Token
      token.revoked = true
      assert.equal token.revoked, true, 'token is revoked'
      assert.equal token.isRevoked(), true, 'isRevoked returns true'
  
  describe 'isActive', ->
    it 'should return true when token is not expired and not revoked', ->
      token = new Token
      assert.equal token.isActive(), true, 'token is active'
    it 'should return false when token is not expired and revoked', ->
      token = new Token
      token.revoked = true
      assert.equal token.isActive(), false, 'token is inactive'
    it 'should return false when token is expired and not revoked', (done) ->
      token = new Token
      setTimeout (->
        assert.equal token.isExpired(), true, 'token is expired'
        assert.equal token.isRevoked(), false, 'token is not revoked'
        assert.equal token.isActive(), false, 'token is inactive'
        done()
      ), tokenExpirationTimeout + 1
    it 'should return false when token is expired and revoked', (done) ->
      token = new Token
      token.revoked = true
      setTimeout (->
        assert.equal token.isExpired(), true, 'token is expired'
        assert.equal token.isRevoked(), true, 'token is revoked'
        assert.equal token.isActive(), false, 'token is inactive'
        done()
      ), tokenExpirationTimeout + 1
