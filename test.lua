-- test.lua - test suite for lib module.

-- 'findbin' -- https://github.com/davidm/lua-find-bin
package.preload.findbin = function()
  local M = {_TYPE='module', _NAME='findbin', _VERSION='0.1.1.20120406'}
  local script = arg and arg[0] or ''
  local bin = script:gsub('[/\\]?[^/\\]+$', '') -- remove file name
  if bin == '' then bin = '.' end
  M.bin = bin
  setmetatable(M, {__call = function(_, relpath) return bin .. relpath end})
  return M
end
package.path = require 'findbin' '/lua/?.lua;' .. package.path

-- from file_slurp 0.4.2.20120406 https://github.com/davidm/lua-file-slurp
local FS = {}
local function check_options(options)
  if not options then return {} end
  local bad = options:match'[^tTsap]'
  if bad then error('ASSERT: invalid option '..bad, 3) end
  local t = {}; for v in options:gmatch'.' do t[v] = true end
  if t.T and t.t then error('ASSERT: options t and T mutually exclusive',3) end
  return t
end
function FS.writefile(filename, data, options)
  local tops = check_options(options)
  local open = tops.p and io.popen or io.open
  local ok
  local fh, err, code = open(filename,
      (tops.a and 'a' or 'w') .. ((tops.t or tops.p) and '' or 'b'))
  if fh then
    ok, err, code = fh:write(data)
    if ok then ok, err, code = fh:close() else fh:close() end
  end
  if not ok then return fail(tops, err, code, filename) end
  return data
end

local M = require 'lib'
assert(#M.cpath ~= 0)
M.cpath = {'<dir>/?.so', '<dir>/?.dll'}

local function checkeq(a, b, e)
  if a ~= b then error(
    'not equal ['..tostring(a)..'] ['..tostring(b)..'] ['..tostring(e)..']', 2)
  end
end

local sep = package.config:sub(3,3)

local function P(paths) return (paths:gsub(';', sep)) end

-- test split
local function ssplit(s) return table.concat(M.split(s), '\0') end
checkeq( ssplit(''), '' )
checkeq( ssplit(P';'), '' )
checkeq( ssplit(P';;'), '' )
checkeq( ssplit(P'./?.lua'), './?.lua' )
checkeq( ssplit(P'./?.lua;/foo/?.lua'), './?.lua\0/foo/?.lua' )

-- test join
checkeq( M.join{}, '')
checkeq( M.join{'./?.lua'}, './?.lua')
checkeq( M.join{'./?.lua', '/foo/?.lua'}, P'./?.lua;/foo/?.lua' )

-- test after
package.path = ''; package.cpath = ''
M.after('foo')
checkeq(package.path, P'foo/?.lua;foo/?/init.lua')
checkeq(package.cpath, P'foo/?.so;foo/?.dll')
M.after('bar')
checkeq(package.path, P'foo/?.lua;foo/?/init.lua;bar/?.lua;bar/?/init.lua')
checkeq(package.cpath, P'foo/?.so;foo/?.dll;bar/?.so;bar/?.dll')
package.path = ''; package.cpath = ''
local ok, err = pcall(function() M.after('a?b') end)
assert(err:match'contains a %?') -- '?' can't be escaped
local ok, err = pcall(function() M.after('a'..sep) end)
assert(err:match'contains a %?') -- ';' can't be escaped

-- test before
package.path = ''; package.cpath = ''
M.before('foo')
checkeq(package.path, P'foo/?.lua;foo/?/init.lua')
checkeq(package.cpath, P'foo/?.so;foo/?.dll')
M.before('bar')
checkeq(package.path, P'bar/?.lua;bar/?/init.lua;foo/?.lua;foo/?/init.lua')
checkeq(package.cpath, P'bar/?.so;bar/?.dll;foo/?.so;foo/?.dll')

-- test before shorthand
package.path = ''
M 'foo'
checkeq(package.path, P'foo/?.lua;foo/?/init.lua')

-- test complex
package.cpath = '?.z'
M {before='a', after={'b','c'}, cpath='<dir>/?.dllx'}
checkeq(package.cpath, P'a/?.dllx;?.z;b/?.dllx;c/?.dllx')

-- test newrequire
FS.writefile('tmp135.x', 'return {}')
M.path = {'<dir>/?.x'}
local require2 = M.newrequire('.')
local X = require2 'tmp135'
assert(X)
os.remove 'tmp135.x'
package.path = '?.lua'
local require2 = M.newrequire{before='a', after={'b','c'}, path='<dir>/?.luac'}
local path
package.preload._lib_debug = function()
  path = package.path
end
require2 '_lib_debug'
checkeq(path, 'a/?.luac;?.lua;b/?.luac;c/?.luac')

-- findbin tests
package.loaded.findbin = nil
arg[0] = 'a/b/c.lua'  -- trick findbin
if pcall(require, 'findbin') then
  package.path = ''; package.cpath = ''
  M.path =  {'<dir>/?.lua', '<dir>/?/init.lua'}
  M.before('<bin>/../foo')
  checkeq(package.path, P'a/b/../foo/?.lua;a/b/../foo/?/init.lua')
else
  print 'WARNING: tests with findbin skipped (module not found)'
end

print 'OK'
