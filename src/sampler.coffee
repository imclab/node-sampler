stream = require './stream'
simple = require './simple'
Record = require './record'

module.exports
  Record: Record
  SimpleRecorder: simple.Recorder
  SimplePlayer  : simple.Player
  StreamRecorder: stream.Recorder
  StreamPlayer  : stream.Player
