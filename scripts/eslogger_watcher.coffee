# Description:
#   logger that transmits messages to elasticsearch
#
# Author:
#   mose

moment = require('moment')
ESLogger = require '../lib/eslogger'

module.exports = (robot) ->

  robot.eslogger ?= new ESLogger(robot)
  eslogger = robot.eslogger

  if eslogger.logEnabled? and eslogger.logEnabled isnt 'false'
    robot.hear /.*/, (msg) ->
      log = {
        room: msg.message.room
        nick: msg.message.user.name
        message: msg.message.text
      }
      eslogger.logMessageES log, msg.message.room, msg

    # hubot don't `hear` its own messages, we have to log them separately
    logMessageFromRobot = (room, text) ->
      log = {
        room: room
        nick: robot.name
        message: text
      }
      eslogger.logMessageES log, room, robot

    robot.logMessageFromRobot = logMessageFromRobot
