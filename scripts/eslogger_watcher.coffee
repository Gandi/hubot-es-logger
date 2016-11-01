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

    override(robot.adapter, 'send', after( (envelope, strings...) ->
      if envelope.room?
        for str in strings
          logMessageFromRobot envelope.room, str
    ))

    # normal message on channel
    robot.hear /.*/, (msg) ->
      log = {
        room: msg.message.room
        nick: msg.message.user.name
        message: msg.message.text
      }
      eslogger.logMessageES log, msg.message.room, msg

    robot.enter (res) ->
      console.log res

    robot.leave (res) ->
      console.log res
