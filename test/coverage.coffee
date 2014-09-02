path = require 'path'
coffeeCoverage = require 'coffee-coverage'

coffeeCoverage.register
  path: 'relative'
  basePath: path.join __dirname, '..'
  exclude: ['test', 'node_modules', '.git']
  initAll: true
  streamlinejs: true
