rootController = require('./controller/root')


module.exports = (app) ->
  app.get('/', rootController.index)
