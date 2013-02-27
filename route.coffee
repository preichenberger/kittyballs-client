rootController = require('./controller/root')


module.exports = (app) ->
  app.get('/broadcast', rootController.broadcast)
  app.get('/', rootController.index)
