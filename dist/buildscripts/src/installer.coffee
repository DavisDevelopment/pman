fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

tools = require './tools'

deb_installer = require 'electron-installer-debian'
win_installer = require 'electron-installer-windows'
installer_funcs = {
    win32: win_installer
    linux: deb_installer
}

class Installer extends tools.Task
    constructor: (@platform, @arch='x64') ->
        super()
        @method = switch (@platform.toLowerCase())
            when 'win32' then win_installer
            when 'linux' then deb_installer
            else null
        @options = {
            src: tools.scriptdir('releases', "pman-#{@platform}-#{@arch}")
            dest: tools.scriptdir('installers')
            arch: @arch
        }
        @promptMessage = "create installer for #{@platform}-#{@arch}"
        @promptDefault = no

    perform: (callback) ->
        @method(@options, callback)

exports['InstAller'] = class InstAller extends tools.Batch
    constructor: ->
        super()
        @tasks = [
            new Installer( 'linux' )
            new Installer( 'win32' )
        ]

    confirm: (f) ->
        _.defer(_.partial(f, null, yes))
