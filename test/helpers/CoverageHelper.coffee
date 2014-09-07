path = require 'path'
coffeeCoverage = require 'coffee-coverage'

# instruments source coffeescript files for test coverage
module.exports = coffeeCoverage.register
  path: 'relative'
  basePath: path.join __dirname, '../..'
  exclude: ['test', 'node_modules', '.git']
  initAll: true
  streamlinejs: true
