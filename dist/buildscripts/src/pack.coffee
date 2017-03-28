
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

tools = require './tools'
standalone = require './standalone'
{PackBuild} = require './standalone'

module.exports = pack = ( argv ) ->
    builds = []
    
    builds.push new PackBuild('linux', 'x64')
    builds.push new PackBuild('win32', 'ia32')
    builds.push new PackBuild('win32', 'x64')

    task = (b, f) -> b.execute(f)
    tasks = (_.partial(task, b) for b in builds)

    async.series tasks, (err, result) ->
        if err?
            console.error err
        else
            console.log " -- Done -- "

do ->
    argv = process.argv[2..]
    pack( argv )
