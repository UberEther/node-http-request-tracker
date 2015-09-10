[![Build Status](https://travis-ci.org/UberEther/node-http-request-tracker.svg?branch=master)](https://travis-ci.org/UberEther/node-http-request-tracker)
[![NPM Status](https://badge.fury.io/js/node-http-request-tracker.svg)](http://badge.fury.io/js/node-http-request-tracker)

# Overview

This library provides a class to track current, recent, and long-running requests within a Node HTTP server.

This is useful for debugging and operational monitoring and can be used to find problem pages or diagnose stuck requests.  

# Examples of use:

```
var HttpRequestTracker = require("node-http-request-tracker");
var http = require("http");

var svr = http.createServer();
var tracker = new HttpShutdownManager(svr);

// Ideally expose information from tracker to your administrative, health-check, and/or monitoring pages
```

# API

## new NodeHttpRequestTracker(httpServer, options)

Creates a new request tracker for the specified HTTP server.  Options supported are:
- numRecent (default = 10) - number of recent requests to retain
- numLongRunning (default = 10) - number of long running requests to retain
- longRunningThreshold (default = 30000) - requests taking longer than this are considered long-running

## pendingRequests
	A hash of current requests.  Each request is assigned an index and removed upon completion

	The objects are in the same format as longRequests

## recentRequests
	An array with the last N requests accepted by the server.  The requests may not yet be complete.  

	The objects are in the same format as longRequests

## longRequests
	An array with the last N long-running requests completed by the server.  These requests are guarenteed to be complete

	The objects contains:
		- req: The request object
		- res: The response object
		- reqDate: Time the request was received
		- resDate: Time the response was sent

## countByCode
	A hash containing the count of the number of responses for each HTTP result code

## reset()
Resets all tracked metrics.  In-flight requests are not reset

## shutdown(cb)
Closes the server and proceedes to start closing connections.  Once all connections are closed, the callback is called.

Returns a promise that is resolved when all connections are closed.

# Contributing

Any PRs are welcome but please stick to following the general style of the code and stick to [CoffeeScript](http://coffeescript.org/).  I know the opinions on CoffeeScript are...highly varied...I will not go into this debate here - this project is currently written in CoffeeScript and I ask you maintain that for any PRs.