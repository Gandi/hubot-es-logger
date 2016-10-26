# Description:
#   annonce to user joining channels where to find the url for browsing the logs for this channel
#
# Author:
#   mose

ESLogger = require '../lib/eslogger'

module.exports = (robot) ->

  robot.eslogger ?= new ESLogger(robot)
  eslogger = robot.eslogger

  if eslogger.logAnnounce? and eslogger.logAnnounce isnt "false"
    robot.enter (msg) ->
      unless eslogger.missingEnvironmentForApi(msg)
        room = msg.message.user.room
        if room in eslogger.logRooms
          if msg.message.user.name != robot.name
            delete msg.message.user.room
            msg.send "Check the logs on #{eslogger.getLogURL(room)}"
