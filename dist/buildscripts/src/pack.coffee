
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

tools = require './tools'
standalone = require './standalone'
{Pack, PackAll} = require './standalone'
{InstallerBuild} = require './installer'

module.exports = pack = ( argv ) ->
    packall = new PackAll()
    packall.execute ->
        console.log " Nigger Anus "

do ->
    argv = process.argv[2..]
    pack( argv )
