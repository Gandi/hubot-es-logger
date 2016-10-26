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

  if eslogger.logEnabled? and eslogger.logEnabled isnt "false"
    robot.hear /.*/, (msg) ->
      log = {}
      log.nick = msg.message.user.name
      log.message = msg.message.text
      log.room = msg.message.room
      # console.log log
      eslogger.logMessageES log, msg.message.room, msg

    logMessageFromRobot = (room, text) ->
      log = {}
      log.nick = robot.name
      log.message = text
      log.room = room
      # console.log log
      eslogger.logMessageES log, room, robot

    robot.logMessageFromRobot = logMessageFromRobot
