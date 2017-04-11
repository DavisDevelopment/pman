
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

tools = require './tools'
standalone = require './standalone'
{Pack, PackAll} = require './standalone'
{Installer,InstAller} = require './installer'

module.exports = pack = ( argv ) ->
    packall = new PackAll()
    install = new InstAller()
    packall.execute ->
        install.execute ->
            console.log " -- DONE -- "

do ->
    argv = process.argv[2..]
    pack( argv )
