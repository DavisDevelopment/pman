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

exports['InstallerBuild'] = class InstallerBuild extends tools.Build
    constructor: (platform, arch) ->
        super()

        @platform = platform
        @arch = arch
        @options = {
            src: tools.scriptdir('releases', "pman-#{@platform}-#{@arch}")
            dest: tools.scriptdir('installers')
            arch: @arch
        }

    execute: (callback) ->
        self = this
        @confirm (err, doit) =>
            if doit
                self.getf()?(self.options, callback)
            else
                _.defer(_.partial(callback, null, null))

    getf: ->
        return installer_funcs[@platform]

    confirm: (callback) ->
        tools.promptBool("create #{@platform}-#{@arch} installer?", no, callback)
