dotenv = require 'dotenv'
assert = require('chai').assert

dotenv.load()

describe 'Token', ->
  Token = require '../../app/models/Token'
  tokenExpirationTimeout = parseInt process.env.TOKEN_EXPIRATION_TIMEOUT_MILLISECONDS, 10
  describe 'defaults', ->
    it 'should include a 128-character token_string', ->
      token = new Token
      assert.isString token.token_string, 'token_string is a string'
      assert.lengthOf token.token_string, 128, 'token_string is 128 characters'
    it 'should include a created_on date', ->
      token = new Token
      assert.ok token.created_on instanceof Date, 'created_on is an Date'
    it 'should include a expires_on date', ->
      token = new Token
      assert.ok token.expires_on instanceof Date, 'expires_on is an Date'
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
        token.compareToken token_string, (err, isMatch) ->
          throw err if err
          assert.equal isMatch, true, 'tokens match'
          done()
    it 'should not match when token_string and token_hash do not match', (done) ->
      token = new Token
      token_string = 'some random non-token string'
      token.validate (err) ->
        token.compareToken token_string, (err, isMatch) ->
          throw err if err
          assert.equal isMatch, false, 'tokens do not match'
          done()
    it 'should not match when token_string and token_hash match and token is expired', (done) ->
      token = new Token
      token_string = token.token_string
      token.validate (err) ->
        token.compareToken token_string, (err, isMatch) ->
          throw err if err
          assert.equal isMatch, true, 'tokens match'
          setTimeout (->
            token.compareToken token_string, (err, isMatch) ->
              throw err if err
              assert.equal token.isExpired(), true, 'isExpired returns true'
              assert.equal isMatch, false, 'tokens do not match'
              done()
          ), tokenExpirationTimeout
    it 'should not match when token_string and token_hash do not match and token is expired', (done) ->
      token = new Token
      token_string = 'some random non-token string'
      token.validate (err) ->
        token.compareToken token_string, (err, isMatch) ->
          throw err if err
          assert.equal isMatch, false, 'tokens do not match'
          setTimeout (->
            token.compareToken token_string, (err, isMatch) ->
              throw err if err
              assert.equal token.isExpired(), true, 'isExpired returns true'
              assert.equal isMatch, false, 'tokens do not match'
              done()
          ), tokenExpirationTimeout
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
      ), tokenExpirationTimeout
