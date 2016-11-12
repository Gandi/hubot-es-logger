moment = require 'moment'
path   = require 'path'

class ESLogger

  constructor: (@robot) ->
    @logEnabled = process.env.ES_LOG_ENABLED
    @logAnnounce = process.env.ES_LOG_ANNOUNCE
    @logESUrl = process.env.ES_LOG_ES_URL
    @logRooms = process.env.ES_LOG_ROOMS.split(',')
    @logIndexName = process.env.ES_LOG_INDEX_NAME or 'irclogs'
    @logSingleIndex = process.env.ES_LOG_SINGLE_INDEX
    @logKibanaUrlName = process.env.ES_LOG_KIBANA_URL
    @logKibanaTemplateName = process.env.ES_LOG_KIBANA_TEMPLATE


  missingEnvironmentForApi: (msg) ->
    missingAnything = false
    unless @logESUrl?
      msg.send 'Ensure that ES_LOG_ES_URL is set.'
      missingAnything |= true
    unless @logRooms?
      msg.send 'Ensure that ES_LOG_ROOMS is set.'
      missingAnything |= true
    missingAnything


  getLogURL: (room) ->
    process.env.HUBOT_BASE_URL + path.join(@robot.name, 'logs', room.replace(/#/, ''))

  logMessageES: (log, room, msg, timestamp = null) ->
    unless @missingEnvironmentForApi(msg)
      if room in @logRooms
        timestamp ?= moment.utc().format()
        log['@timestamp'] = timestamp
        json = JSON.stringify(log)
        if @logSingleIndex? and @logSingleIndex isnt 'false'
          index = @logIndexName
        else
          index = @logIndexName + '-' + moment.utc().format('YYYY.MM.DD')
        @robot.http(@logESUrl)
          .path(index + '/line')
          .post(json) (err, res, body) =>
            # console.log res.statusCode
            if res.statusCode is 404
              json_body = JSON.parse(body)
              if json_body.error.type is 'index_not_found_exception'
                @createIndex index, =>
                  # console.log "re-launch"
                  @logMessageES log, room, msg
              else
                @robot.logger.warning 'logMessageES / res.statusCode == 400 ' +
                                      'and json_body.error.type != index_not_found_exception'
                @robot.logger.warning res.statusCode
                @robot.logger.warning body
            else
              if res.statusCode > 299
                @robot.logger.warning 'logMessageES / res.statusCode > 299'
                @robot.logger.warning res.statusCode
                @robot.logger.warning body
              else
                @robot.logger.debug 'logged.'

  createIndex: (index, cb) ->
    mapping = {
      mapping: {
        line: {
          properties: {
            '@timestamp': {
              type: 'date',
              format: 'dateOptionalTime'
            },
            message: {
              type: 'string',
              norms: {
                enabled: false
              },
              fields: {
                raw: {
                  type: 'string',
                  index: 'not_analyzed',
                  ignore_above: 256
                }
              }
            },
            nick: {
              type: 'string',
              norms: {
                enabled: false
              },
              fields: {
                raw: {
                  type: 'string',
                  index: 'not_analyzed',
                  ignore_above: 256
                }
              }
            },
            room: {
              type: 'string',
              norms: {
                enabled: false
              },
              fields: {
                raw: {
                  type: 'string',
                  index: 'not_analyzed',
                  ignore_above: 256
                }
              }
            }
          }
        }
      }
    }
    json = JSON.stringify(mapping)
    @robot.http(@logESUrl)
      .path(index)
      .put(json) (err, res, body) =>
        if res.statusCode > 299
          @robot.logger.warning 'createIndex / res.statusCode > 299'
          @robot.logger.warning res.statusCode
          @robot.logger.warning body
        else
          cb()

  getLogs: (room, start, stop, cb) ->
    # would be good to replace this with a filter, we don't need relevance
    query = {
      query: {
        bool: {
          must: [
            {
              range: {
                '@timestamp': {
                  from: start,
                  to: stop
                }
              }
            },
            {
              match_phrase: {
                room: room
              }
            }
          ]
        }
      },
      sort: {
        '@timestamp': {
          order: 'asc'
        }
      },
      size: 1000
    }
    json = JSON.stringify(query)
    # console.log json
    if @logSingleIndex? and @logSingleIndex isnt 'false'
      @searchES @logIndexName, json, (body) ->
        cb body.hits.hits
    else
      index = @logIndexName + '-' + start.format('YYYY.MM.DD')
      index_end = @logIndexName + '-' + stop.format('YYYY.MM.DD')
      if index is index_end
        @searchES index, json, (body) ->
          cb body.hits.hits
      else
        @searchES index, json, (body) ->
          @searchES index_end, json, (body_end) ->
            cb body.hits.hits.concat(body_end.hits.hits)

  getLastTerm: (room, term, cb) ->
    query = {
      query: {
        bool: {
          must: [
            {
              match_phrase: {
                message: term
              }
            },
            {
              match_phrase: {
                room: room
              }
            }
          ],
          must_not: {
            match_phrase: {
              message: '.recall '
            }
          }
        }
      },
      sort: {
        '@timestamp': {
          order: 'desc'
        }
      },
      size: 1
    }
    json = JSON.stringify(query)
    @searchAllES json, (body) ->
      cb body.hits.hits

  getLinesPerDay: (room) ->
    query = {
      query: {
        match_phrase: {
          room: room
        }
      },
      size: 0,
      aggs: {
        lines_per_day: {
          field: '@timestamp',
          interval: 'day'
        }
      }
    }
    json = JSON.stringify(query)
    @searchAllES json, (body) ->
      cb body.hits.hits

  searchAllES: (json, cb) ->
    if @logSingleIndex? and @logSingleIndex isnt 'false'
      url = '/' + @logIndexName + '/_search'
    else
      url = '/' + @logIndexName + '-*/_search'
    @robot.http(@logESUrl)
      .path(url)
      .get(json) (err, res, body) ->
        switch res.statusCode
          when 200 then json_body = JSON.parse(body)
          else
            @robot.logger.warning 'searchAllES / res.statusCode != 200'
            console.log res.statusCode
            console.log body
            json_body = null
        cb json_body

  searchES: (index, json, cb) ->
    @robot.http(@logESUrl)
      .path(index + '/_search')
      .post(json) (err, res, body) ->
        switch res.statusCode
          when 200 then json_body = JSON.parse(body)
          else
            @robot.logger.warning 'searchES / res.statusCode != 200'
            console.log res.statusCode
            console.log body
            json_body = null
        cb json_body

  logContent: (room, lines, start, stop) ->
    time = moment().utc().format('HH:mm')
    start_date = start.format('MMM, ddd Do HH:mm')
    stop_date = stop.format('MMM, ddd Do HH:mm')
    content = @html_head(room)
    content += """
          <div>from #{start_date} to #{stop_date} - Times are UTC (now is #{time} UTC)</div>
          <br>
          <div class="commands">
        """
    for line in lines
      time = moment(line._source['@timestamp']).utc().format('HH:mm:ss')
      if line._source.nick? and line._source.nick isnt ''
        content += "<p>#{time} <span>#{escape line._source.nick}</span>: "
        content += "#{@escape line._source.message}</p>"
      else
        content += "<p>#{time} <span>&nbsp;</span>: "
        content += "<i>#{@escape line._source.message}</i></p>"
    content += '</div>'
    content += @foot_html()
    content

  html_head: (room) ->
    """
    <html>
      <head>
      <meta charset="utf-8" />
      <title>#{@title room}</title>
      <style type="text/css">
        body {
          background: #d3d6d9;
          color: #555;
          text-shadow: 0 1px 1px rgba(255, 255, 255, .5);
          font-family: sans serif;
        }
        h1 {
          margin: 8px 0;
          padding: 0;
        }
        p {
          font-family: monospace;
          border-bottom: 1px solid #eee;
          padding: 2px 0;
          margin: 0;
          color: #111;
        }
        p span {
          width: 120px;
          display: inline-block;
          text-align: right;
          font-weight: bold;
        }
        p > i {
          color: #666;
        }
        p:hover {
          color: #000;
          background-color: #fff;
        }
        a {
          text-decoration: none;
          color: #249;
        }
        a:hover {
          background-color: #ee9;
        }
        .foot {
          padding: 20px 10px;
          margin-top: 30px;
          background-color: #a3a6a9;
        }
      </style>
      </head>
      <body>
        <h1>#{@title room, 'html'}</h1>
    """

  title: (room, html = null) ->
    if room?
      room = " for #{room}"
    else
      room = ''
    if html?
      "<a href=\"/#{@robot.name}/logs\">Irc Logs</a>#{room}"
    else
      "Irc Logs#{room}"

  foot_html: ->
    if @logKibanaUrlName?
      url = @logKibanaUrlName + '/#/dashboard/file/' + @logKibanaTemplateName + '.json?room=' + room
      "<div class=\"foot\">More Power on <a href=\"#{url}\">#{url}</a></div></body></html>"
    else
      '</body></html>'

  escape: (message) ->
    return message.replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/(https?:\/\/[^ ]*)/, ($1) ->
        "<a href=\"#{$1}\">#{$1}</a>"
        )



module.exports = ESLogger
