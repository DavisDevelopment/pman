
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

tools = require './tools'
standalone = require './standalone'
{Build} = require './standalone'

module.exports = pack = ( argv ) ->
    standalone_builds = [new Build('linux', 'x64'), new Build('win32', 'ia32'), new Build('win32', 'x64')]

    Build.buildAll standalone_builds, (error) ->
        if error?
            console.error( error )
        else
            console.log " -- Done Building Standalones -- "

do ->
    argv = process.argv[2..]
    pack( argv )
