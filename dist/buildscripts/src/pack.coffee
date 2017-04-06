
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

tools = require './tools'
standalone = require './standalone'
{PackBuild} = require './standalone'
{InstallerBuild} = require './installer'

module.exports = pack = ( argv ) ->
    builds = []
    
    ask_pack = (callback) ->
        maybe_pack = (err, val) ->
            if val
                builds.push new PackBuild('linux', 'x64')
                builds.push new PackBuild('win32', 'ia32')
                builds.push new PackBuild('win32', 'x64')
            callback null, null
        tools.promptBool("perform packing tasks?", no, maybe_pack)

    ask_intallers = (callback) ->
        maybe_installers = (err, val) ->
            if val
                builds.push new InstallerBuild('linux', 'x64')
                builds.push new InstallerBuild('win32', 'ia32')
                builds.push new InstallerBuild('win32', 'x64')
            callback null, null
        tools.promptBool("perform installer tasks?", no, maybe_installers)

    async.series [ask_pack, ask_intallers], ->
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
