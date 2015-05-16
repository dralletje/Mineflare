net = require 'net'
Promise = require 'bluebird'

#getServer = require './lib/getServer'
#debug = require('debug')('mineflare')

# Load models from config
config = require('js-yaml').safeLoad require('fs').readFileSync('./config.yml').toString()
getmyip = require './getip'

if not config.etcd?
  console.error 'No `etcd` section in config found!'
  process.exit()

Etcd = require 'node-etcd'
Promise.promisifyAll(Etcd.prototype)
etcd = new Etcd(config.etcd.host, config.etcd.port)

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
    if not data? then return
    data

## Removed breakerror in favour of beter errorhandling
#class BreakError extends Error then constructor: -> super

# Dragoman!
Dragoman = require 'dragoman'
protocol = require './minecraft-interface'

dragoman = new Dragoman
packets = dragoman.compile protocol

kick = (client, message, code=500) ->
  client.end if client.state is 2
      packets.kick.build [JSON.stringify text: "#{message} (#{code})"]
    else
      packets.status.build [
        JSON.stringify
        	version:
        		name: "ERR #{code}"
        		protocol: 5
        	description:
        		text: message
      ]

# Error predicates
Key_not_found_error = (e) ->
  e.message is 'Key not found'

Server_unavailable_error = (e) ->
  e.message is 'All servers returned error'

###
Actual server
###
net.createServer (client) ->
  client.on 'error', (e) ->
    if e.code is 'EPIPE'
      return # Other end has closed the connection
    console.log 'Error in minecraft handling:', e.stack

  suck(client).then (data) ->
    [version, host, port, state] = packet = packets.handshake.extract(data, false)
    client.handshake = packet

    if not version?
      throw new Error 'Bad Package! Require handshake! ' + old.toString()

    client.state = state

    host = host.toLowerCase()
    etcd.getAsync('/minecraft/'+host).then (result) ->
      result[0].node.value

  .then (to) ->
    [host, port] = to.split ':'
    server = net.createConnection(port or 25565, host)

    server.on 'error', (e) ->
      kick client, "Server is offline", 502

    #nullbyte = new Buffer([0])
    delimiter = "|"
    ###client.handshake[1] = client.handshake[1] + delimiter + client.remoteAddress
      + nullbyte + client.remoteAddress
      + nullbyte + ###

    client.handshake[1] = client.handshake[1] + delimiter + client.remoteAddress
    console.log 'Going to send:', client.handshake[1]

    data = packets.handshake.build client.handshake

    server.write data
    client.pipe(server).pipe(client)

  # Error handling
  .catch Key_not_found_error, ->
    kick client, "No server at this address!", 404

  .catch Server_unavailable_error, ->
    kick client, "Proxies overloaded, sorry", 502

  .catch (err) ->
    kick client, 'Protocol error!', 400
    return

    console.error '== ERROR =='
    console.error err.stack
    console.error err
    kick client, 'ZOMBIE APOCALYPSE!!!', 500

.on 'error', (e) ->
  console.error 'Error in Minecraft.coffee:', e.stack

.listen 25565, ->
  # Set server to available in the central DB
  getmyip().then (me) ->
    jsonme = JSON.stringify(me)
    ttl = 10
    update = ->
      etcd.set "/proxy/"+me.ip, jsonme, ttl: ttl

    update()
    # Update 5 seconds before ttl ends
    setInterval update, (ttl - 5) * 1000
