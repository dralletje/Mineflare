net = require 'net'
Promise = require 'bluebird'

#getServer = require './lib/getServer'
debug = require('debug')('mineflare')

# Load models from config
config = require('js-yaml').safeLoad require('fs').readFileSync('./config.yml').toString()
{sequelize, Server} = require('./models')(config.mysql)

###
Extending the prototypes :o
###
wait = (emitter, event) ->
  new Promise (resolve, reject) =>
    emitter.once event, (args...) ->
      resolve args[0]
    .once 'error', (err) ->
      reject err

suck = (stream) ->
  wait(stream, 'readable').then ->
    data = stream.read()
    if not data? then throw new Error 'hey'
    data


###
Dragoman!
###
Dragoman = require 'dragoman'
protocol = require './minecraft-interface'

dragoman = new Dragoman
packets = dragoman.compile protocol

kick = (client, message, code=500) ->
  client.end if client.state is 2
      packets.kick.build(JSON.stringify text: "#{message} (#{code})")
    else
      packets.status.build JSON.stringify
      	version:
      		name: "ERR #{code}"
      		protocol: 5
      	description:
      		text: message

###
Actual server
###
net.createServer (client) ->
  debug 'Client connection!'

  client.on 'error', (e) ->
    if e.code is 'EPIPE'
      return # Other end has closed the connection
    console.log 'Error in minecraft handling:', e

  suck(client).then (data) ->
    client.handshake = data
    [version, host, port, state] = packets.handshake.extract data

    if not version?
      throw new Error 'Bad Package! Require handshake! ' + old.toString()

    debug 'state:', (if state is 1 then 'Pingin\'' else 'Playing')
    client.state = state

    host = host.toLowerCase()
    #getServer host, Models
    Server.find where: name: host

  .then (to) ->
    if not to?
      kick client, "No server at this address!", 404
    else
      server = net.createConnection(to.port, to.host)

      server.on 'error', (e) ->
        kick client, "Server has an error", 502

      server.write client.handshake
      client.pipe(server).pipe(client)

  .catch (err) ->
    debug '== ERROR =='
    console.log 'Ssst (minecraft.coffee):', err.stack
    kick client, 'ZOMBIE APOCALYPSE!!!', 500

.on 'error', (e) ->
  console.log 'Error in Minecraft.coffee:', e.stack

.listen 25565
