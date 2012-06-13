// Generated by CoffeeScript 1.3.3
(function() {
  var contains, delay, error, inspect, log, moment, _, _ref, _ref1,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ref = require('util'), log = _ref.log, error = _ref.error, inspect = _ref.inspect;

  _ = require('underscore');

  moment = require('moment');

  _ref1 = require('./misc/toolbox'), delay = _ref1.delay, contains = _ref1.contains;

  module.exports = (function() {

    function exports(options) {
      this.fire = __bind(this.fire, this);

      this.resume = __bind(this.resume, this);

      this.pause = __bind(this.pause, this);
      this.store = options.record.store;
      this.rate = options.rate;
      this.looped = options.looped;
      this.onError = options.on.error;
      this.onData = options.on.data;
      this.onEnd = options.on.end;
      this.enabled = true;
      this.paused = false;
      this.next = false;
      this.latency = 0;
    }

    exports.prototype.pause = function() {
      this.paused = true;
      return this.latency = 0;
    };

    exports.prototype.resume = function() {
      if (!this.enabled) {
        this.onEnd();
        this.onError("cannot resume: we are not enabled");
        return;
      }
      this.paused = false;
      if (!this.next) {
        this.next = this.store.first;
      }
      return this.fire();
    };

    exports.prototype.fire = function() {
      var evt, fired,
        _this = this;
      if (!this.enabled) {
        this.onEnd();
        this.onError("cannot fire: we are not enabled");
        return;
      }
      if (this.paused) {
        log("cannot fire: paused");
        return;
      }
      evt = this.next;
      if (!evt) {
        this.onEnd();
        this.onError("cannot fire: next is empty()");
        return;
      }
      fired = moment();
      this.onData({
        timestamp: evt.timestamp,
        data: evt.data
      });
      return this.store.next(evt, function(next) {
        var dbLatency, realDelay, theoricDelay;
        if (next === _this.store.first) {
          _this.onEnd();
          if (!_this.looped) {
            _this.enabled = false;
            _this.onEnd();
            return;
          }
        }
        theoricDelay = (next.timestamp - evt.timestamp) / _this.rate;
        dbLatency = moment() - fired - Math.abs(latency);
        realDelay = theoricDelay - dbLatency;
        if (realDelay < 0) {
          _this.latency = realDelay;
          realDelay = 0;
        }
        _this.next = next;
        return delay(realDelay, function() {
          return _this.fire();
        });
      });
    };

    return exports;

  })();

}).call(this);