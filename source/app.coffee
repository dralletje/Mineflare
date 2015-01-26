net = require 'net'
Promise = require 'bluebird'

#getServer = require './lib/getServer'
debug = require('debug')('mineflare')

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
    console.log 'Error in minecraft handling:', e.stack

  suck(client).then (data) ->
    client.handshake = data
    [version, host, port, state] = packets.handshake.extract data

    if not version?
      throw new Error 'Bad Package! Require handshake! ' + old.toString()

    debug 'state:', (if state is 1 then 'Pingin\'' else 'Playing')
    client.state = state

    host = host.toLowerCase()
    etcd.getAsync '/minecraft/'+host

  .then (to) ->
    [host, port] = to[0].node.value.split ':'
    server = net.createConnection(port or 25565, host)

    server.on 'error', (e) ->
      kick client, "Server has an error", 502

    server.write client.handshake
    client.pipe(server).pipe(client)

  .catch (err) ->
    if err.cause?.errorCode is 100
      debug 'Server not found!'
      kick client, "No server at this address!", 404
    else
      console.error '== ERROR =='
      console.error err.stack
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
