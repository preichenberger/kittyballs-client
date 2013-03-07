config = require('singleconfig')
events = require('events')
io = require('socket.io-client')
roundRobot = require('node-sphero')

# Sphero
sphero = new roundRobot.Sphero()
spheroLock = false
spheroEmitter = new events.EventEmitter()
spheroPingId = null
sphero.on('connected', (ball) ->
  spheroLock = false
  spheroEmitter.emit('connected', ball)
  console.log('Connected to sphero')
)

# Sphero connect
spheroEmitter.on('disconnected', () ->
  if spheroLock
    return

  if sphero.balls.length > 0
    sphero = new roundRobot.Sphero()

  spheroLock = true
  console.log('Connecting to sphero...')
  sphero.connect()
  spheroLock = false
)

# Sphero ping
spheroPingId = setInterval(
  () ->
    if sphero.balls.length > 0
      ball = sphero.balls[0]
      ball.ping((err) ->
        if err && !spheroLock
          spheroEmitter.emit('disconnected')
      )
    else
      spheroEmitter.emit('disconnected')
  , 5000
)

# Color randomizer
color = () ->
  r = Math.random() * 255
  g = Math.random() * 255
  b = Math.random() * 255
  return [r,g,b]

# Socketio server
socketPingIds = {}
socket = io.connect(config.socketio.server,
  reconnect: false
)
socket.on('connect', () ->
  console.log('socketio started')

  socketPingIds[socket.id] = setInterval(
    () ->
      socket.emit('message',
        action: 'ping',
        broadcastKey: config.broadcastkey
      )
    config.socketio.pinginterval
  )

  socket.emit('message',
    action: 'join'
    broadcastKey: config.broadcastkey
    role: 'publisher'
  )

  socket.on('message', (data) ->
    if sphero.balls.length == 0 || spheroLock
      return

    ball = sphero.balls[0]

    switch data.action
      when 'roll'
        console.log('roll')
        ball.roll(0, .5)
      when 'back'
        console.log('back')
        ball.roll(0, 0)
      when 'left'
        console.log('left')
        ball.setHeading(315)
      when 'right'
        console.log('right')
        ball.setHeading(45)
      when 'color'
        rgb = color()
        ball.setRGBLED(rgb[0], rgb[1], rgb[2], false)
  )
  socket.on('disconnect', () ->
    clearInterval(socketPingIds[socket.id])
    socket.removeAllListeners('message')
    socket.socket.reconnect()
  )
)

process.on('SIGINT', () ->
  console.log('exiting')
  if sphero.balls.length > 0
    try
      sphero.close()
    catch err

  spheroEmitter.removeAllListeners()
  socket.disconnect()
  clearInterval(spheroPingId)
  process.exit()
)
