# Description:
#   logger that transmits messages to elasticsearch
#
# Author:
#   mose

moment = require('moment')

module.exports = (robot) ->

  if logAnnounce? and logAnnounce isnt "false"
    robot.enter (msg) ->
      if !missingEnvironmentForApi(msg)
        room = msg.message.user.room
        if room in logRooms
          if msg.message.user.name != robot.name
            delete msg.message.user.room
            msg.send "Check the logs on #{getLogURL(room)}"

  if logEnabled? and logEnabled isnt "false"
    robot.hear /.*/, (msg) ->
      log = {}
      log.nick = msg.message.user.name
      log.message = msg.message.text
      log.room = msg.message.room
      # console.log log
      logMessageES log, msg.message.room, msg

    logMessageFromRobot = (room, text) ->
      log = {}
      log.nick = robot.name
      log.message = text
      log.room = room
      # console.log log
      logMessageES log, room, robot

    robot.logMessageFromRobot = logMessageFromRobot
