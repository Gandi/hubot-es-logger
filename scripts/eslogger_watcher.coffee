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

    # hubot don't `hear` its own messages, we have to 'decorate'
    # the adapter `send` method to add an after-method

    override = (object, methodName, callback) ->
      object[methodName] = callback(object[methodName])

    after = (extra) ->
      (original) ->
        () ->
          returnValue = original.apply(this, arguments)
          extra.apply(this, arguments)
          returnValue

    logMessageFromRobot = (room, text) ->
      log = {
        room: room
        nick: robot.name
        message: text
      }
      faketime = moment.utc().add(1, 'second').format()
      eslogger.logMessageES log, room, robot, faketime

    override robot.adapter, 'send', after (envelope, strings...) ->
      if envelope.room?
        for str in strings
          logMessageFromRobot envelope.room, str
    

    # normal message on channel
    robot.hear /.*/, (res) ->
      log = {
        room: res.message.room
        nick: res.message.user.name
        message: res.message.text
      }
      eslogger.logMessageES log, res.message.room, res

    robot.enter (res) ->
      msg = res.envelope.message
      line = "#{msg.user.name} has joined #{msg.room} (#{msg.text})"
      eslogger.logMessageES line, msg.room, res

    robot.leave (res) ->
      msg = res.envelope.message
      line = "#{msg.user.name} has quit #{msg.room}"
      eslogger.logMessageES line, msg.room, res
