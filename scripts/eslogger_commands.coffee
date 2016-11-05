# Description:
#   commands to interact with the logs
#
# Commands:
#   hubot log version - give the version of hubot-es-logger loaded
#   hubot log         - give the url where to find the logs for this channel
#
# Author:
#   mose

path = require 'path'
moment = require 'moment'
ESLogger = require '../lib/eslogger'

module.exports = (robot) ->

  robot.eslogger ?= new ESLogger(robot)
  eslogger = robot.eslogger

#   hubot log version - give the version of hubot-es-logger loaded
  robot.respond /logs? version\s*$/, (res) ->
    pkg = require path.join __dirname, '..', 'package.json'
    res.send "hubot-es-logger is version #{pkg.version}"

  robot.respond /logs$/, (res) ->
    room = res.message.user.room
    if room in eslogger.logRooms
      res.send "Check the logs on #{eslogger.getLogURL(room)}"
    else
      res.send "This room (#{room}) is not logged."

  robot.respond /recall (.*)$/, (res) ->
    room = res.message.user.room
    if room?
      eslogger.getLastTerm room, res.match[1], (result) ->
        if result.length > 0
          data = result[0]['_source']
          timestamp = moment(data['@timestamp']).format('YYYY-MM-DD HH:mm')
          res.send "#{timestamp} <#{data.nick}> #{data.message}"
        else
          res.send "Sorry I cannot find any occurence of '#{res.match[1]}' on this channel."
    else
      res.send 'This command can only be asked in a channel.'
