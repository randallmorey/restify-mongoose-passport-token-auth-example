dotenv = require 'dotenv'
assert = require('chai').assert

dotenv.load()

describe 'Integration: Token', ->
  DatabaseHelper = require '../helpers/DatabaseHelper'
  Token = require '../../app/models/Token'
  longRunningTests = process.env.LONG_RUNNING_TESTS is 'true'
  tokenExpirationTimeout = parseInt process.env.TOKEN_EXPIRATION_TIMEOUT_MILLISECONDS, 10
  
  beforeEach (done) ->
    DatabaseHelper.connect ->
      DatabaseHelper.empty Token, done
  
  afterEach (done) ->
    DatabaseHelper.disconnect done
  
  describe 'expiration', ->
    it 'should not remove unexpired tokens', (done) ->
      token = new Token
      token.save (err) ->
        throw err if err
        Token.count (err, count) ->
          throw err if err
          assert.equal count, 1, 'one saved token'
          assert.equal token.isExpired(), false, 'token is unexpired'
          done()
    if longRunningTests
      it 'should remove expired tokens 60 seconds after expiration', (done) ->
        timeout = tokenExpirationTimeout + (60 * 1000)
        @timeout timeout + 1000
        token = new Token
        token.save (err) ->
          throw err if err
          Token.count (err, count) ->
            throw err if err
            assert.equal count, 1, 'one saved token'
            setTimeout (->
              Token.count (err, count) ->
                throw err if err
                assert.equal count, 0, 'no saved tokens'
                assert.equal token.isExpired(), true, 'token is expired'
                done()
            ), timeout + 100
