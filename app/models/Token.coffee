dotenv = require 'dotenv'
mongoose = require 'mongoose'
bcrypt = require 'bcrypt'

dotenv.load()

TokenSchema = mongoose.Schema
  token_string:
    type: String
    default: ->
      # generates a token of random alphanumeric characters
      maxLength = 256
      mask = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      (mask[Math.floor(Math.random() * (mask.length - 1))] for i in [0...maxLength]).join('')
  token_hash:
    type: String
    required: true
  revoked:
    type: Boolean
    default: false
  created_on:
    type: Date
    required: true
    default: Date.now
  expires_on:
    type: Date
    required: true
    expires: 0
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

TokenSchema.methods.isExpired = ->
  expirationTime = @expires_on.getTime()
  Date.now() >= expirationTime
  
TokenSchema.methods.isRevoked = ->
  !!@revoked

TokenSchema.methods.isActive = ->
  !@isExpired() and !@isRevoked()

TokenSchema.methods.compareToken = (candidateTokenId, candidateToken, next) ->
  if candidateTokenId?.toString() == @_id?.toString()
    bcrypt.compare candidateToken, @token_hash, (err, isMatch) ->
      next err, isMatch
  else
    next null, false

Token = mongoose.model 'Token', TokenSchema
module.exports = Token
