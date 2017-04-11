
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

coffee = require 'coffee-script'
less = require 'less'
ugly = require 'ugly'

tools = require './tools'
{Build,Builds,Task,Batch} = tools

exports['concat'] = concat = (inputs, output, callback) ->
    async.map inputs, fs.readFile, (err, buffs) ->
        sum = ''
        sum += b for b in buffs
        sum = Buffer.from sum
        fs.writeFile(output, sum, callback)


