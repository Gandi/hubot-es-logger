# Description:
#   commands to interact with the logs
#
# Commands:
#   hubot log version - give the version of hubot-es-logger loaded
#   hubot log         - give the url where to find the logs for this channel
#
# Author:
#   mose

path = require('path')
moment = require('moment')
ESLogger = require '../lib/eslogger'

module.exports = (robot) ->

  robot.eslogger ?= new ESLogger(robot)
  eslogger = robot.eslogger

#   hubot log version - give the version of hubot-es-logger loaded
  robot.respond /logs? version\s*$/, (res) ->
    pkg = require path.join __dirname, '..', 'package.json'
    res.send "hubot-es-logger is version #{pkg.version}"
    res.finish()

  robot.respond /logs$/, (msg) ->
    room = msg.message.user.room
    if room in eslogger.logRooms
      msg.send "Check the logs on #{eslogger.getLogURL(room)}"

  robot.respond /recall (.*)$/, (msg) ->
    room = msg.message.user.room
    if room?
      eslogger.getLastTerm room, msg.match[1], (result) ->
        if result.length > 0
          data = result[0]['_source']
          timestamp = moment(data['@timestamp']).format('YYYY-MM-DD HH:mm')
          msg.send "#{timestamp} <#{data.nick}> #{data.message}"
        else
          msg.send "Sorry I cannot find any occurence of '#{msg.match[1]}' on this channel."
    else
      msg.send 'This command can only be asked in a channel.'

