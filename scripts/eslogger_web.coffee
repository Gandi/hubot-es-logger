# Description:
#   web server to browse channels logs
#
# URLS:
#   /hubot/logs/<channel>
#
# Author:
#   mose

moment = require 'moment'
ESLogger = require '../lib/eslogger'

module.exports = (robot) ->

  robot.eslogger ?= new ESLogger(robot)
  eslogger = robot.eslogger

  robot.router.get "/#{robot.name}/logs", (req, res) ->
    content = eslogger.html_head(null)
    for room in eslogger.logRooms.sort()
      content += "<p><span></span><a href=\"/#{robot.name}/logs/#{room.slice(1)}\">#{room}</a></p>"
    content += eslogger.foot_html()
    res.setHeader 'content-type', 'text/html'
    res.end content

  robot.router.get "/#{robot.name}/logs/:room", (req, res) ->
    room = req.params.room
    if room and '#' + room in eslogger.logRooms
      duration = 24
      room = '#' + room
      start = moment.utc().subtract(duration, 'hours')
      stop = moment.utc()
      eslogger.getLogs room, start, stop, (json_body) ->
        res.setHeader 'content-type', 'text/html'
        res.end eslogger.logContent(room, json_body, start, stop)
    else
      res.setHeader 'content-type', 'text/plain'
      res.status(404).end 'Unkown room.'
