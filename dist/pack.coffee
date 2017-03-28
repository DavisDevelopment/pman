
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

packager = require 'electron-packager'
deb_installer = require 'electron-installer-debian'
win_installer = require 'electron-installer-windows'

scriptdir = (__dirname + '')

defaltOptions =
  dir: scriptdir
  name: 'pman'
  arch: 'x64'
  version: '1.6.2'
  out: path.join(scriptdir, 'releases')
  'app-bundle-id': ''
  'app-version': ''
  overwrite: true
  asar: true
  prune: true
  icon: path.join(scriptdir, 'assets/icon32.png')
  app_version: '0.1.2'
  bundle_id: ''
  appname: 'pman'
  sourcedir: scriptdir
  ignore: path.join(scriptdir, 'releases')

options = (o...) -> _.extend(_.clone(defaltOptions), o...)

# task registry
actions = {}

# Package PMan for Linux and Windows
build_releases = actions['pack'] = ( complete ) ->
    complete ?= (-> null)
    builds = []
    #pack_cb = ((error, appPaths) -> if error? then console.error(error) else console.log(appPaths))
    #pack_task = (settings) -> return _.bind(packager, options(settings))
    pack_task = (o) -> (cb) -> packager(options( o ), cb)
    plan = (settings) ->
        builds.push pack_task( settings )

    # Linux Build
    plan
        platform: 'linux'

    # Windows Build for ia32
    plan
        platform: 'win32'
        arch: 'ia32'

    # Windows Build for x64
    plan
        platform: 'win32'
        arch: 'x64'

    async.series builds, (error, paths) ->
        if error?
            console.error error
        else
            console.log _.flatten paths
            console.log ' -- PMan Packaged for Linux and Windows -- '
        do complete

# Build the .deb installer
build_debian_installer = actions['debian_installer'] = ( complete ) ->
    complete ?= (-> null)
    release_dir = path.join(scriptdir, 'releases', 'pman-linux-x64')
    installers_dir = path.join(scriptdir, 'installers')
    
    console.log "creating debian installer for pman"
    options =
        src  : release_dir
        dest : installers_dir
        arch : 'x64'

    #deb_installer callback
    dicb = (error) ->
        if error?
            console.error( error )
        else
            console.log " -- Created Debian Installer for PMan -- "
        do complete

    deb_installer(options, dicb)

# Build the Windows installer
build_windows_installer = actions['windows_installer'] = ( complete ) ->
    complete ?= (-> null)
    release_dir = (arch) -> path.join(scriptdir, 'releases', "pman-windows-#{arch}")
    installers_dir = path.join(scriptdir, 'installers')
    builds = []
    itask = (o) -> (callback) -> win_installer(o, callback)
    plan = (o) -> builds.push itask o
    opts = (arch) ->
        src  : release_dir arch
        dest : installers_dir
        arch : arch

    plan opts 'ia32'
    plan opts 'x64'

    callback = (error) ->
        if error?
            console.error error
        else
            console.log " -- Created Windows Installers for PMan -- "
            do complete

    async.series(builds, callback)

# 'main' function
do ->
    # get parameters
    actionNames = process.argv[2..]
    if not actionNames.length
        actionNames.push 'all'
    actionNames = actionNames.map (s) -> s.toLowerCase()
    do ->
        if actionNames[0] == 'installers'
            actionNames = ['debian_installer', 'windows_installer']
    tasks = do ->
        if actionNames.length == 1
            switch actionNames[0]
                when 'all'
                    for name of actions then actions[name]
                else
                    [actions[actionNames[0]]]
        else
            for name in actionNames
                if name of actions
                    actions[name]
    taskCallback = (error) ->
        if error?
            console.error error

    async.series tasks, taskCallback

