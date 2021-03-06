
# Copyright (c) 2011, Julian Bilcke <julian.bilcke@daizoru.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of Julian Bilcke, Daizoru nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL JULIAN BILCKE OR DAIZORU BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# standard modules
{log,error,inspect} = require 'util'
{Stream} = require 'stream'

# third party modules
moment = require 'moment'

# project modules
{delay,contains,simpleFactory} = require '../misc/toolbox'
Record = require '../record'
Cursor = require '../cursor'

# SIMPLE API
class exports.Recorder
  constructor: (url="",options={}) ->
    @config =
      autosave: 500

    for k,v of options
      @config[k] = v

    # Simple API use simple callbacks
    @callbacks = []
    @sync = 0
    @synced = no
    @closed = no

    #log "SimpleRecorder#constructor(#{url})"
    @record = simpleFactory Record, url

    @record.on 'error', (data) =>
      if data.version > @sync
        @sync = data.version
        for cb in @callbacks
          delay 0, -> cb(data.err) # error
        @callbacks = []
      else
        1 # the event arrived to late - we just ignore it

    @record.on 'synced', (version) =>
      @synced = (version > 0)
      if version > @sync
        @sync = version
        for cb in @callbacks
          delay 0, -> cb() # no error
        @callbacks = []
      else
        1 # the event arrived to late - we just ignore it

    if @config.autosave >= 0
      if @record.ready()
        delay @config.autosave, => @autosave()
      else
        @record.on 'ready', =>
          @autosave()

  autosave: =>
    #log "AUTOSAVE"
    if @synced
      # if we are closed AND synced -> stop loop
      if @closed
        @config.autosave = -1
        return
    else
      @record.sync()
    if @config.autosave >= 0
      delay @config.autosave, =>
        @autosave()

  # SimpleRecorder API
  write: (data, cb=no) => 
    @writeAt moment(), data, cb

  # SimpleRecorder API
  writeAt: (timestamp, data, cb=no) => 
    @callbacks.push cb if cb
    @synced = @record.write timestamp, data
    @synced

  close: =>
    @closed = yes

  
class exports.Player
  constructor: (url, options={}) -> 
    #log "simple.Player#constructor(#{url}, options)"

    @config =
      speed: 1.0
      autoplay: yes
      withTimestamp: no
      looped: no
      onBegin: ->
      onData: (tm,data) -> #log "#{tm}: #{data}"
      onEnd: ->
      onError: (err) ->

    for k,v of options
      @config[k] = v

    # record can emit events
    @record = simpleFactory Record, url

    # cursor emit events
    @cursor = new Cursor
      record: @record
      speed: @config.speed
      looped: @config.looped

    # register cursor events  
    @cursor.on 'begin', => 
      delay 0, => @config.onBegin()

    if @config.withTimestamp
      @cursor.on 'data', (data)   => @config.onData data.timestamp, data.data
    else
      @cursor.on 'data', (data)   => @config.onData data.data
    @cursor.on   'end',           => @config.onEnd()
    @cursor.on   'error', (err)   => @config.onError err

    if @config.autoplay
      if @record.ready()
        delay 0, => @resume()
      else
        @record.on 'ready', =>
          @resume()

  start:  => @resume()
  resume: => @cursor.resume()
  pause:  => @cursor.pause()
