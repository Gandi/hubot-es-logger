require('es6-promise').polyfill()

Helper = require 'hubot-test-helper'
helper = new Helper('../scripts/eslogger_commands.coffee')
Hubot = require '../node_modules/hubot'

path   = require 'path'
nock   = require 'nock'
sinon  = require 'sinon'
expect = require('chai').use(require('sinon-chai')).expect

room = null

describe 'eslogger_commands', ->

  hubotHear = (message, userName = 'momo', tempo = 40) ->
    beforeEach (done) ->
      room.user.say userName, message
      setTimeout (done), tempo

  hubot = (message, userName = 'momo') ->
    hubotHear "@hubot #{message}", userName

  hubotResponse = (i = 1) ->
    room.messages[i]?[1]

  hubotResponseCount = ->
    room.messages?.length - 1

  say = (command, cb) ->
    context "\"#{command}\"", ->
      hubot command
      cb()

  only = (command, cb) ->
    context.only "\"#{command}\"", ->
      hubot command
      cb()

  beforeEach ->
    do nock.enableNetConnect
    process.env.ES_LOG_ROOMS = 'room1'
    process.env.ES_LOG_ENABLED = 'true'
    process.env.HUBOT_BASE_URL = 'http://localhost:8080/'
    room = helper.createRoom { httpd: false }
    room.robot.brain.userForId 'user', {
      name: 'user'
    }

    room.receive = (userName, message) ->
      new Promise (resolve) =>
        @messages.push [userName, message]
        user = { name: userName, id: userName, room: 'room1' }
        @robot.receive(new Hubot.TextMessage(user, message), resolve)

  afterEach ->
    delete process.env.ES_LOG_ROOMS
    delete process.env.ES_LOG_ENABLED
    delete process.env.HUBOT_BASE_URL

  # ------------------------------------------------------------------------------------------------
  say 'log version', ->
    it 'replies version number', ->
      expect(hubotResponse()).to.match /hubot-es-logger is version [0-9]+\.[0-9]+\.[0-9]+/

  context 'when room1 is logged', ->
    say 'logs', ->
      it 'gives the url of the web interface', ->
        expect(hubotResponse()).to.eql 'Check the logs on http://localhost:8080/hubot/logs/room1'

  context 'when room1 is not logged', ->
    beforeEach ->
      room.robot.eslogger.logRooms = [ 'notlogged' ]
    say 'logs', ->
      it 'tells the room is not logged', ->
        expect(hubotResponse()).to.eql 'This room (room1) is not logged.'

