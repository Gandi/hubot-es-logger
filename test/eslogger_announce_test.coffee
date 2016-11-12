require('es6-promise').polyfill()

Helper = require 'hubot-test-helper'
helper = new Helper('../scripts/eslogger_announce.coffee')
Hubot = require '../node_modules/hubot'

path   = require 'path'
nock   = require 'nock'
sinon  = require 'sinon'
expect = require('chai').use(require('sinon-chai')).expect

room = null

describe 'eslogger_commands', ->

  hubotEnter = (userName = 'momo', tempo = 40) ->
    beforeEach (done) ->
      room.user.enter userName
      setTimeout (done), tempo

  hubotResponse = (i = 0) ->
    room.messages[i][1]

  hubotResponseCount = ->
    room.messages?.length - 1

  beforeEach ->
    do nock.enableNetConnect
    process.env.ES_LOG_ROOMS = 'room1'
    process.env.HUBOT_BASE_URL = 'http://localhost:8080/'
    process.env.ES_LOG_ES_URL = 'http://localhost:9292/'
    process.env.ES_LOG_ANNOUNCE = 'true'
    room = helper.createRoom { httpd: false }

  afterEach ->
    delete process.env.ES_LOG_ENABLED
    delete process.env.HUBOT_BASE_URL
    delete process.env.ES_LOG_ES_URL
    delete process.env.ES_LOG_ANNOUNCE

  # ------------------------------------------------------------------------------------------------
  context 'a user joins', ->
    hubotEnter 'momo'
    it 'gives him a private message with weblogs url', ->
      expect(hubotResponse()).to.eql 'Check the logs on http://localhost:8080/hubot/logs/room1'

