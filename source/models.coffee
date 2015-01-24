Sequelize = require 'sequelize'

###
jwt = require 'jwt-simple'
JWT_KEY = 'XGpDAHhUmThSz4SuEe5sppdK'
_ = require 'lodash'
###

module.exports = (mysql) ->
  sequelize = new Sequelize mysql.database, mysql.user, mysql.password, mysql # Other options like 'host'

  ## Mysql models
  Server = sequelize.define 'Server',
    name: Sequelize.STRING
    host: Sequelize.STRING
    port: Sequelize.INTEGER

  sequelize
    .authenticate()
    .then ->
      console.log('Connection has been established successfully.')
    .catch (err) ->
      console.log('Unable to connect to the database:', err)

  sequelize.sync()

  Server: Server
  sequelize: sequelize
