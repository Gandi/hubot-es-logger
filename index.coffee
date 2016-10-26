path = require 'path'

features = [
  'announce',
  'watcher',
  'commands',
  'web'
]

module.exports = (robot) ->
  
  for feature in features
    robot.logger.debug "Loading eslogger_#{feature}"
    robot.loadFile(path.resolve(__dirname, 'scripts'), "eslogger_#{feature}.coffee")
