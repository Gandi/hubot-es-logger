class ESLogger

  constructor: (@robot) ->
    @logEnabled = process.env.ES_LOG_ENABLED
    @logAnnounce = process.env.ES_LOG_ANNOUNCE
    @logESUrl = process.env.ES_LOG_ES_URL
    @logRooms = process.env.ES_LOG_ROOMS.split(',')
    @logIndexName = process.env.ES_LOG_INDEX_NAME
    @logKibanaUrlName = process.env.ES_LOG_KIBANA_URL
    @logKibanaTemplateName = process.env.ES_LOG_KIBANA_TEMPLATE


  missingEnvironmentForApi: (msg) ->
    missingAnything = false
    unless @logESUrl?
      msg.send 'Ensure that GANDI_LOG_ES_URL is set.'
      missingAnything |= true
    unless @logRooms?
      msg.send 'Ensure that GANDI_LOG_ROOMS is set.'
      missingAnything |= true
    unless @logIndexName?
      msg.send 'Ensure that GANDI_LOG_INDEX_NAME is set.'
      missingAnything |= true
    missingAnything


  getLogURL: (room) ->
    process.env.HUBOT_BASE_URL + path.join(robot.name, 'logs', room.slice(1))

  logMessageES: (log, room, msg) ->
    unless missingEnvironmentForApi(msg)
      if room in @logRooms
        date = moment.utc()
        log['@timestamp'] = date.format()
        json = JSON.stringify(log)

        index = @logIndexName + '-' + date.format('YYYY.MM.DD')
        console.log body
        # @robot.http(@logESUrl)
        #   .path(index + '/irclog/')
        #   .post(json) (err, res, body) ->
        #     if res.statusCode > 299
        #       @robot.logger.warning res.statusCode
        #       @robot.logger.warning body

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
    # console.log json
    @searchAllES json, (body) ->
      cb body.hits.hits

  searchAllES: (json, cb) ->
    @robot.http(@logESUrl)
      .path('/logstash-*/_search')
      .get(json) (err, res, body) ->
        switch res.statusCode
          when 200 then json_body = JSON.parse(body)
          else
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
            console.log res.statusCode
            console.log body
            json_body = null
        cb json_body

  logContent: (room, lines, start, stop) ->
    time = moment().utc().format('HH:mm')
    start_date = start.format('MMM, ddd Do HH:mm')
    stop_date = stop.format('MMM, ddd Do HH:mm')
    content = @html_head("<a href=\"/#{robot.name}/logs\">Irc Logs</a> for #{room}")
    content += """
          <div>from #{start_date} to #{stop_date} - Times are UTC (now is #{time} UTC)</div>
          <br>
          <div class="commands">
        """
    for line in lines
      time = moment(line._source['@timestamp']).utc().format('HH:mm')
      content += "<p>#{time} <span>#{escape line._source.nick}</span>: "
      content += "#{escape line._source.message}</p>"
    content += '</div>'
    content += @foot_html()
    content

  html_head: (title) ->
    """
    <html>
      <head>
      <meta charset="utf-8" />
      <title>#{title}</title>
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
        <h1>#{title}</h1>
    """

  foot_html: ->
    if @logKibanaUrlName?
      url = logKibanaUrlName + '/#/dashboard/file/' + logKibanaTemplateName + '.json?room=' + room
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
