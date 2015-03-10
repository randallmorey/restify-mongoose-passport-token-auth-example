class TokenHelper
  @decodeTokenString: (tokenString) ->
    decodedToken = new Buffer(tokenString, 'base64').toString().split ':'
    id: decodedToken[0]
    token_string: decodedToken[1]

module.exports = TokenHelper
