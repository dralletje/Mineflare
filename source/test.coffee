net = require 'net'

Dragoman = require 'dragoman'
protocol = require './minecraft-interface'

dragoman = new Dragoman
packets = dragoman.compile protocol


server = net.createConnection(25565, 'localhost')
now = Date.now()

console.log 'Hi!'

server.on 'error', (e) ->
  console.log e.stack

server.on 'readable', ->
  console.log @read()

server.on 'end', ->
  console.log 'ended'
  console.log (Date.now() - now) / 1000

packet = packets.handshake.build 47, 'localhost', 25565, 1
i = 0

setInterval ->
  console.log 'New ding!'
  server.write packet.slice i++, 0
, 5 * 1000
