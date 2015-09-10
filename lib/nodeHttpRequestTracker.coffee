CappedArray = require "capped-array"

class NodeHttpRequestTracker
    constructor: (@server, options = {}) ->
        @longRunningThreshold = options.longRunningThreshold || 30000
        @numRecent = options.numRecent || 10
        @numLongRunning = options.numLongRunning || 10

        @pendingRequests = {}
        @reset()

        @_onRequestOpen = @_onRequestOpen.bind @
        @_onRequestClose = @_onRequestClose

        @server.on "request", @_onRequestOpen

    reset: () ->
        @index = 0
        @countByCode = {}
        @recentRequests = new CappedArray @numRecent
        @longRequests = new CappedArray @numLongRunning

    _onRequestOpen: (req, res) ->
        t =
            self: @
            index: @index
            reqDate: Date.now()
            req: req
            res: res

        @pendingRequests[@index] = t
        res.__requestTracker = t
        @index++

        this.recentRequests.push t

        res.on "close", @_onRequestClose
        res.on "finish", @_onRequestClose

    _onRequestClose: () ->
        # Cannot bind this API because we need the original "this" from the event
        # So extract it from the embedded object...
        t = @__requestTracker
        return if !t

        delete @__requestTracker
        self = t.self

        t.resDate = Date.now()
        age = t.resDate - t.reqDate

        self.longRequests.push t if age >= self.longRunningThreshold

        code = @statusCode || "unknown"
        self.countByCode[code] = (self.countByCode[code] || 0) + 1

        delete self.pendingRequests[t.index]

module.exports = NodeHttpRequestTracker