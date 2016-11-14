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
      room = '#' + room
      start = moment.utc().hour(0).minutes(0).seconds(0)
      stop = moment.utc()
      eslogger.getLogs room, start, stop, (json_body) ->
        res.setHeader 'content-type', 'text/html'
        res.end eslogger.logContent(room, json_body, start, stop)
    else
      res.setHeader 'content-type', 'text/plain'
      res.status(404).end 'Unkown room.'


  robot.router.get "/#{robot.name}/logs/:room/:day", (req, res) ->
    room = req.params.room
    day = req.params.day.replace(/[^\d]/g, '')
    if day < 0
      res.setHeader 'content-type', 'text/html'
      res.status(404).end "#{req.params.day} cannot be understood as a number."
    else
      if room and '#' + room in eslogger.logRooms
        room = '#' + room
        start = moment.utc().subtract(day, 'days').hour(0).minutes(0).seconds(0)
        stop = moment.utc().subtract(day, 'days').hour(23).minutes(59).seconds(59)
        eslogger.getLogs room, start, stop, (json_body) ->
          res.setHeader 'content-type', 'text/html'
          res.end eslogger.logContent(room, json_body, start, stop)
      else
        res.setHeader 'content-type', 'text/plain'
        res.status(404).end 'Unkown room.'

  robot.router.get "/#{robot.name}/logs/:room/:year/:month/:day", (req, res) ->
    room = req.params.room
    day = moment().utc().year(req.params.year).month(req.params.month - 1).date(req.params.day)
    unless day.isValid()
      res.setHeader 'content-type', 'text/html'
      res.status(404).end "#{req.params.year}/#{req.params.month}/#{req.params.day} " +
                          'cannot be understood as a date.'
    else
      if room and '#' + room in eslogger.logRooms
        room = '#' + room
        start = day.hour(0).minutes(0).seconds(0)
        stop = day.hour(23).minutes(59).seconds(59)
        eslogger.getLogs room, start, stop, (json_body) ->
          res.setHeader 'content-type', 'text/html'
          res.end eslogger.logContent(room, json_body, start, stop)
      else
        res.setHeader 'content-type', 'text/plain'
        res.status(404).end 'Unkown room.'


  robot.router.get "/#{robot.name}/logs/:room/count.json", (req, res) ->
    room = req.params.room
    if room and '#' + room in eslogger.logRooms
      room = '#' + room
      eslogger.getLinesPerDay room, (json_body) ->
        res.setHeader 'content-type', 'application/json'
        res.end json_body
    else
      res.setHeader 'content-type', 'application/json'
      res.status(404).end '{}'
