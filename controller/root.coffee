config = require('singleconfig')

module.exports.index = (req, res) ->
  res.render('root/index')

module.exports.broadcast = (req, res) ->
  locals =
    apiKey: config.tokbox.apikey
    sessionId: config.demo.tokboxSessionId
    token: config.demo.tokboxPublisherToken
    
  res.render('root/broadcast', locals)
