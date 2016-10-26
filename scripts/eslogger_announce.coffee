# Description:
#   annonce to user joining channels where to find the url for browsing the logs for this channel
#
# Author:
#   mose

module.exports = (robot) ->

  if logAnnounce? and logAnnounce isnt "false"
    robot.enter (msg) ->
      if !missingEnvironmentForApi(msg)
        room = msg.message.user.room
        if room in logRooms
          if msg.message.user.name != robot.name
            delete msg.message.user.room
            msg.send "Check the logs on #{getLogURL(room)}"
