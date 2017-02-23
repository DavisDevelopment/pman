
http = require 'http'
ecstatic = require 'ecstatic'

exports['createServer'] = ( options ) ->
	server = http.createServer ecstatic
		root: __dirname

	server.listen 8080

