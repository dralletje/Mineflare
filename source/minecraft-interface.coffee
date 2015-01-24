varint = require('varint').encode

module.exports = (start) ->
  handshake:
    start().withVarintLength start().is(new Buffer varint 0x00).varint().varString().UInt16BE().varint()

  kick:
    start().withVarintLength start().is(new Buffer varint 0x00).varString()

  status:
    start().withVarintLength start().is(new Buffer varint 0x00).varString()
