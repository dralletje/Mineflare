Promise = require 'bluebird'
http = require 'http'

module.exports = getmyip = ->
  new Promise (yell, cry) ->
    http.get 'http://www.telize.com/geoip/', (socket) ->
      bufs = []
      socket.on 'readable', ->
        bufs.push socket.read()
      .on 'end', ->
        yell JSON.parse Buffer.concat(bufs).toString()
      .on 'error', cry

  .then (res) ->
    {longitude, latitude, ip} = res
    
    ip: ip
    location:
      longitude: longitude
      latitude: latitude
