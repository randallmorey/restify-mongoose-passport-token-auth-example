assert = require('chai').assert

describe 'User', ->
  User = require '../../app/models/User'
  
  describe 'defaults', ->
    it 'should include an active boolean that defaults to true', ->
      user = new User
      assert.equal typeof user.active, 'boolean', 'active is a boolean'
      assert.equal user.active, true, 'active is true by default'
    it 'should include a created_on date', ->
      user = new User
      assert.ok user.created_on instanceof Date, 'created_on is an Date'
  
  describe 'validate', ->
    it 'should fail on no values specified', (done) ->
      user = new User
      user.validate (err) ->
        assert.isDefined err, 'user does not validate'
        done()
    it 'should pass on valid email and password', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.validate (err) ->
        assert.isUndefined err, 'valid email produces no error'
        done()
    it 'should fail on missing email', (done) ->
      user = new User password: 'testing1234!'
      user.validate (err) ->
        assert.equal err.errors.email.type, 'required', 'email is required'
        done()
    it 'should fail on invalid email', (done) ->
      user = new User email: 'test@test', password: 'test1234'
      user.validate (err) ->
        assert.equal err.errors.email.type, 'regexp', 'error type is regexp'
        done()
    it 'should pass on missing password', (done) ->
      user = new User email: 'test@test.com'
      user.validate (err) ->
        assert.isUndefined err.errors.password, 'no error on missing password'
        done()
    it 'should fail on invalid password', (done) ->
      user = new User email: 'test@test', password: 'testtest'
      user.validate (err) ->
        assert.equal err.errors.password.type, 'regexp', 'error type is regexp'
        user = new User email: 'test@test', password: '12341234'
        user.validate (err) ->
          assert.equal err.errors.password.type, 'regexp', 'error type is regexp'
          user = new User email: 'test@test', password: 'test123'
          user.validate (err) ->
            assert.equal err.errors.password.type, 'regexp', 'error type is regexp'
            done()
  
  describe 'password', ->
    it 'should not exist after successful validate', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.validate (err) ->
        assert.isUndefined err, 'validation successful'
        assert.isUndefined user.password, 'password does not exist'
        done()
    it 'should not exist after failed validate', (done) ->
      user = new User email: 'test@test.com', password: 'testtest'
      user.validate (err) ->
        assert.equal err.errors.password.type, 'regexp', 'error type is regexp'
        assert.isUndefined user.password, 'password does not exist'
        done()
  
  describe 'password_hash', ->
    it 'should exist after validate', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.validate ->
        assert.isString user.password_hash, 'password_hash exists'
        done()
  
  describe 'comparePassword', ->
    it 'should match when password and password_hash match', (done) ->
      user = new User email: 'test@test.com', password: 'test1234'
      user.validate (err) ->
        user.comparePassword 'test1234', (err, isMatch) ->
          throw err if err
          assert.equal isMatch, true, 'passwords match'
          done()
    it 'should not match when password and password_hash do not match', (done) ->
      user = new User email: 'test@test.com', password: '1234test'
      user.validate (err) ->
        user.comparePassword 'test1234', (err, isMatch) ->
          throw err if err
          assert.equal isMatch, false, 'passwords do not match'
          done()
