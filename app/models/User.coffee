mongoose = require 'mongoose'
bcrypt = require 'bcrypt'

UserSchema = mongoose.Schema
  email:
    type: String
    match: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
    required: true
    unique: true
    lowercase: true
    trim: true
  password:
    type: String
    # must contain at least one character each of:
    # lowercase, numeric, non-alphanumeric
    match: /^(?=.*[a-zA-Z])(?=.*[\d]).{8,}$/
  password_hash:
    type: String
    required: true
  active:
    type: Boolean
    default: true
    required: true
  created_on:
    type: Date
    required: true
    default: Date.now
  tokens: [
    type: mongoose.Schema.Types.ObjectId
    ref: 'Token'
  ]

UserSchema.pre 'validate', (next) ->
  saltWorkFactor = 5
  if @password and @isModified 'password'
    bcrypt.genSalt saltWorkFactor, (err, salt) =>
    	return next err if err
    	bcrypt.hash @password, salt, (err, hash) =>
    		return next err if err
    		@password_hash = hash
    		next()
  else
    next()

UserSchema.post 'validate', ->
  @password = undefined if @password

UserSchema.methods.comparePassword = (candidatePassword, next) ->
	bcrypt.compare candidatePassword, @password_hash, (err, isMatch) ->
		next err, isMatch

User = mongoose.model 'User', UserSchema
module.exports = User
