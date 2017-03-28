
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

before = exports['before'] = (s, what) -> s[...s.indexOf(what)]
after = exports['after'] = (s, what) -> s[(s.indexOf(what) + what.length)...]
divide = exports['divide'] = (s, what) -> [before(s, what), after(s, what)]
