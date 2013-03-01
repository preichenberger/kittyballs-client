config = require('singleconfig')
io = require('socket.io-client')
roundRobot = require('node-sphero')
socket = io.connect(config.socketio.server)

# Sphero
sphero = new roundRobot.Sphero()
spheroLock = false

sphero.on('connected', (ball) ->
  GLOBAL.sphero = ball
  spheroLock = false
  console.log('Connected to sphero')
)

sphero.on('error', (err) ->
  console.log('error')

)

spheroConnect = () ->
  if spheroLock
    console.log('Sphero Locked')
    return

  console.log('Connecting to sphero')

  try
    sphero.close()
  catch e
    console.log('iff')
  delete GLOBAL.sphero
  spher = new roundRobot.Sphero()
  spheroLock = true
  sphero.connect()
  spheroTimeoutId = setTimeout(
    () ->
      if GLOBAL.sphero
        return

      console.log('Sphero connection timed out')
      spheroLock = false
    , 5000
  )

spheroConnect()

# Socket io
color = () ->
  r = Math.random() * 255
  g = Math.random() * 255
  b = Math.random() * 255
  return [r,g,b]

socket.on('connect', () ->
  console.log('socket io up')
  socket.emit('message',
    action: 'join'
    publisherToken: config.publishertoken
    role: 'publisher'
  )

  socket.on('message', (data) ->
    if !GLOBAL.sphero
      spheroConnect()
      return
    else
      console.log('trying to ping')
      GLOBAL.sphero.ping((err) ->
        if err
          spheroConnect()
      )

    switch data.action
      when 'roll'
        console.log('roll')
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
  )
)
