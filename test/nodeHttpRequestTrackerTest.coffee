expect = require("chai").expect
EventEmitter = require("events").EventEmitter

describe "RequestTracker Handler", () ->
    NodeHttpRequestTracker = require "../lib/nodeHttpRequestTracker"

    it "should set correct defaults", () ->
        svr = new EventEmitter
        t = new NodeHttpRequestTracker svr
        expect(t.longRunningThreshold).to.equal(30000)
        expect(t.numRecent).to.equal(10)
        expect(t.recentRequests.size).to.equal(10)
        expect(t.numLongRunning).to.equal(10)
        expect(t.longRequests.size).to.equal(10)

    it "should override defaults", () ->
        svr = new EventEmitter
        t = new NodeHttpRequestTracker svr,
            longRunningThreshold: 1
            numRecent: 2
        expect(t.longRunningThreshold).to.equal(1)
        expect(t.numRecent).to.equal(2)
        expect(t.recentRequests.size).to.equal(2)
        expect(t.numLongRunning).to.equal(10)
        expect(t.longRequests.size).to.equal(10)

        t = new NodeHttpRequestTracker svr,
            longRunningThreshold: 1
            numLongRunning: 2
        expect(t.longRunningThreshold).to.equal(1)
        expect(t.numRecent).to.equal(10)
        expect(t.recentRequests.size).to.equal(10)
        expect(t.numLongRunning).to.equal(2)
        expect(t.longRequests.size).to.equal(2)

    it "should properly track a basic request", () ->
        svr = new EventEmitter
        t = new NodeHttpRequestTracker svr

        req = {}
        res = new EventEmitter
        svr.emit "request", req, res
        expect(t.index).to.equal(1)
        expect(t.pendingRequests["0"]).to.be.ok
        expect(t.pendingRequests["0"].self).to.equal(t)
        expect(t.pendingRequests["0"].index).to.equal(0)
        expect(t.pendingRequests["0"].req).to.equal(req)
        expect(t.pendingRequests["0"].res).to.equal(res)
        expect(t.countByCode).to.deep.equal({})
        expect(t.recentRequests.length).to.equal(1)
        expect(t.recentRequests[0]).to.be.ok
        expect(t.recentRequests[0].self).to.equal(t)
        expect(t.recentRequests[0].index).to.equal(0)
        expect(t.recentRequests[0].req).to.equal(req)
        expect(t.recentRequests[0].res).to.equal(res)
        expect(t.longRequests.length).to.equal(0)

        res.emit "close"
        expect(t.index).to.equal(1)
        expect(t.pendingRequests["0"]).to.equal(undefined)
        expect(t.countByCode).to.deep.equal({ "unknown": 1 })
        expect(t.recentRequests.length).to.equal(1)
        expect(t.recentRequests[0]).to.be.ok
        expect(t.recentRequests[0].self).to.equal(t)
        expect(t.recentRequests[0].index).to.equal(0)
        expect(t.recentRequests[0].req).to.equal(req)
        expect(t.recentRequests[0].res).to.equal(res)
        expect(t.longRequests.length).to.equal(0)


    it "should properly track long running requests", () ->
        svr = new EventEmitter
        t = new NodeHttpRequestTracker svr, longRunningThreshold: -1

        req = {}
        res = new EventEmitter
        svr.emit "request", req, res
        res.emit "close"

        expect(t.longRequests.length).to.equal(1)
        expect(t.longRequests[0]).to.be.ok
        expect(t.longRequests[0].self).to.equal(t)
        expect(t.longRequests[0].index).to.equal(0)
        expect(t.longRequests[0].req).to.equal(req)
        expect(t.longRequests[0].res).to.equal(res)

    it "should properly track result codes", () ->
        svr = new EventEmitter
        t = new NodeHttpRequestTracker svr, longRunningThreshold: -1

        req = {}
        res = new EventEmitter
        res.statusCode = 200
        svr.emit "request", req, res
        res.emit "close"

        expect(Object.keys(t.countByCode)).to.deep.equal(["200"])
        expect(t.countByCode["200"]).to.equal(1)

    it "should tolerate a double-closed result", () ->
        svr = new EventEmitter
        t = new NodeHttpRequestTracker svr

        req = {}
        res = new EventEmitter
        res.statusCode = 200
        svr.emit "request", req, res
        res.emit "close"
        res.emit "finish"

        expect(Object.keys(t.countByCode)).to.deep.equal(["200"])
        expect(t.countByCode["200"]).to.equal(1)
