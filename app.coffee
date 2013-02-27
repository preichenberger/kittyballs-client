config = require('singleconfig')
express = require('express')
OpenTok = require('opentok')
redis = require('redis')
roundRobot = require('node-sphero')
url = require('url')

app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

# Sphero
sphero = new roundRobot.Sphero()
sphero.on('connected', (ball) ->
  GLOBAL.sphero = ball
  console.log('Connected to sphero')
)
sphero.connect()

# Redis
redisURL = url.parse(config.redis.url)
redisAuth = redisURL.auth.split(':')
GLOBAL.redisClient = redis.createClient(
  redisURL.port,
  redisURL.hostname
)
GLOBAL.redisClient.auth(redisAuth[1])

# OpenTok
GLOBAL.opentokClient = new OpenTok.OpenTokSDK(config.apikey, config.apisecret)

# Views
app.set('view engine', 'jade')
app.set('views', "#{__dirname}/view")

# Middleware
app.use(express.cookieParser())
app.use(express.bodyParser())
app.use(express.logger('short'))
app.use(express.errorHandler())


# Local variables
app.locals.config = config
app.locals.pretty = true
app.locals.io = io

# Routes
require('./route')(app)

server.listen(config.port)
console.log("Started app on port: #{config.port}")

# Socket io
color = () ->
  r = Math.random() * 255
  g = Math.random() * 255
  b = Math.random() * 255
  return [r,g,b]


io.sockets.on('connection', (socket) ->
  console.log('socket io up')
  socket.emit('connected', { connected: true })
  socket.on('message', (data) ->
    if !GLOBAL.sphero
      sphero.connect()

    console.log(data)
    switch data.action
      when 'roll'
        if GLOBAL.sphero
          GLOBAL.sphero.roll(0, .5)
      when 'back'
        console.log('back')
        if GLOBAL.sphero
          GLOBAL.sphero.roll(0, 0)
      when 'left'
        console.log('left')
        if GLOBAL.sphero
          sphero.setHeading(315)
      when 'right'
        console.log('right')
        if GLOBAL.sphero
          sphero.setHeading(45)
      when 'color'
        rgb = color()
        if GLOBAL.sphero
          GLOBAL.sphero.setRGBLED(rgb[0], rgb[1], rgb[2], false)
      else
        console.log('bad key')
  )
)
