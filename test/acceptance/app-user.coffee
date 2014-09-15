supertest = require 'supertest'

describe 'Acceptance: User', ->
  app = require '../../server.coffee'
  DatabaseHelper = require '../helpers/DatabaseHelper'
  User = require '../../app/models/User'
  
  beforeEach (done) ->
    DatabaseHelper.connect ->
      DatabaseHelper.empty User, done
  
  afterEach (done) ->
    DatabaseHelper.disconnect done
  
  describe '/users', ->
    describe 'POST', ->
      it 'should create and return a new user [201]', (done) ->
        supertest(app)
          .post '/users'
          .send
            email: 'test@test.com'
            password: 'test1234'
          .expect 201, done
      it 'should disallow creation of a user when email and password are missing [409]', (done) ->
        supertest(app)
          .post '/users'
          .expect 409
          .expect
            code: 'InvalidArgument'
            message: 'Email and password required.'
          .end done
      it 'should disallow creation of a user with duplicate email [409]', (done) ->
        supertest(app)
          .post '/users'
          .send
            email: 'test@test.com'
            password: 'test1234'
          .expect 201
          .end (err) ->
            throw err if err
            supertest(app)
              .post '/users'
              .send
                email: 'test@test.com'
                password: 'test1234'
              .expect 409
              .expect
                code: 'InvalidArgument'
                message: 'Email is already taken.'
              .end done
      it 'should disallow creation of a user with invalid email [409]', (done) ->
        supertest(app)
          .post '/users'
          .send
            email: 'test@test.c'
            password: 'test1234'
          .expect 409
          .expect
            code: 'InvalidArgument'
            message: 'Path `email` is invalid (test@test.c).'
          .end done
      it 'should disallow creation of a user with invalid password [409]', (done) ->
        supertest(app)
          .post '/users'
          .send
            email: 'test@test.com'
            password: 'thisemailcontainsnonumbers'
          .expect 409
          .expect
            code: 'InvalidArgument'
            message: 'Path `password` is invalid (thisemailcontainsnonumbers).'
          .end done
