dotenv = require 'dotenv'
mongoose = require 'mongoose'
bcrypt = require 'bcrypt'

dotenv.load()

TokenSchema = mongoose.Schema
  token_string:
    type: String
    default: ->
      # generates a random-length (64-128 characters) token of random characters
      maxLength = 128
      mask = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~`!@#$%^&*()_+-={}[]:";\'<>?,./|\\'
      (mask[Math.floor(Math.random() * (mask.length - 1))] for i in [0...maxLength]).join('')
  token_hash:
    type: String
    required: true
  user_agent:
    type: String
  created_on:
    type: Date
    required: true
    default: Date.now
  expires_on:
    type: Date
    required: true
    default: ->
      tokenExpirationTimeout = parseInt process.env.TOKEN_EXPIRATION_TIMEOUT_MILLISECONDS, 10
      Date.now() + tokenExpirationTimeout

TokenSchema.pre 'validate', (next) ->
  saltWorkFactor = 5
  if @token_string
    bcrypt.genSalt saltWorkFactor, (err, salt) =>
    	return next err if err
    	bcrypt.hash @token_string, salt, (err, hash) =>
    		return next err if err
    		@token_hash = hash
    		next()
  else
    next()

TokenSchema.post 'validate', ->
  @token_string = undefined

TokenSchema.methods.isExpired = (next) ->
  expirationTime = @expires_on.getTime()
  Date.now() >= expirationTime

TokenSchema.methods.compareToken = (candidateToken, next) ->
  if @isExpired()
    next null, false
  else
    bcrypt.compare candidateToken, @token_hash, (err, isMatch) ->
      next err, isMatch

Token = mongoose.model 'Token', TokenSchema
module.exports = Token
