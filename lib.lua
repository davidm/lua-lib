--[[ FILE README.txt

LUA MODULE

  lib v$(_VERSION) - Simple insertion of directories in package search paths.
  
SYNOPSIS

  require 'lib' '/foo/bar'  -- or, equivalently, `require 'lib'.prepend '/foo/bar'`
    -- adds given directory to package.path and package.cpath.
  require 'lib'.append '/foo/baz'   -- or adds after existing path templates
  local LIB = require 'lib'
  LIB.split(package.path) --> {'/foo/bar/?.lua', '/foo/bar/?/init.lua', . . . ,
                          --   '/foo/baz/?.lua', '/foo/baz/?/init.lua'}
  
  -- custom template formats
  require 'lib'.path = {'<dir>/?.luac', '<dir>/.lua'}
  require 'lib'.prepend '/foo/bar'
  print(package.path) --> '/foo/bar/?.luac;/foo/bar/?.lua; . . .'

DESCRIPTION

  Adding a directory to the package search paths (`package.path` and
  `package.cpath`) can be a chore.  There can be multiple template
  variants to add such as '<dir>/?.lua' and '<dir>/?/init.lua'.
  This module simplifies that.

API

  LIB.prepend(dir)
  
    Prepends templates for directory `dir` to `package.path` and `package.cpath`.
    Template patterns in `LIB.template` are used to build the templates.  Example:
    
      require 'lib'.prepend'/foo/bar'
    
  LIB.append(dir)
  
    Same as `LIB.prepend` but appends rather than prepends.

  LIB (dir)
  
    This is the same as `LIB.prepend(dir)`.  Example:
    
      require 'lib' '/foo/bar'
    
  LIB.split(paths)
  
    Splits package search string `paths` (in the format expected by
    `package.path` or `package.searchpath`) into an array of path templates:
    
      LIB.split('/foo/bar/?.so;/baz/?.so') --> {'/foo/bar/?.so', '/baz/?.so'}
    
  LIB.path / LIB.cpath
  
    This is a table containing the formats of templates inserted into
    `package.path` and `package.cpath` by `LIB.prepend` and
    `LIB.append`.  For example,
  
      LIB.path = {'<dir>/?.lua', '<dir>/?/init.lua'}
      LIB.cpath = {'<dir>/?.so', '<dir>/?.dll'}

    Any '<dir>' in these templates is replaced by the path being added.
    
  LIB.newrequire( [dir...] ) -> require
  
    This builds a `require` like function that prepends the given directories
    to the search paths, invokes the original `require` function, and then
    restores the search paths.
     
       do
         local require = require 'lib'.newrequire('/foo/bar', '/bar/foo')
         local BAZ = require 'baz'  -- searches inside /foo/bar & /bar/foo
      end
      local QUX = require 'qux'  -- does not search inside /foo/bar & /bar/foo

    Note: The new paths will also be visible if require is recursively invoked
    from the module being loaded.
    
    WARNING: The interface of the `newrequire` function is subject to change.
    We may want to allow adding templates explicitly (rather than directories)
    and removing templates from the paths searched by require.
    
DESIGN NOTES

  '<dir>/?.lua' preceeds '<dir>/?/init.lua' as in luaconf.h.  This in
  theory allows a module to be named 'init'.
  
  .luac files are not by default included in LIB.path (same as in luaconf.h).  It
  may be argued that compiled bytecode just as well be given a .lua extension.
  
  `LIB.prepend`, `LIB.append`, and `LIB.path/cpath` cause global side-effects.
  After all, `require` utilizes `package.path` and `package.cpath` globals.

DEPENDENCIES

  None (other than Lua 5.1 or 5.2).
  
HOME PAGE

  https://gist.github.com/1342319
  
DOWNLOAD/INSTALL

  If using LuaRocks:
    luarocks install lua-lib

  Otherwise, download <https://raw.github.com/gist/1342319/globtopattern.lua>.
  Alternately, if using git:
    git clone git://gist.github.com/1342319.git lua-lib
    cd lua-lib
  Optionally unpack and install in LuaRocks:
    Download <https://raw.github.com/gist/1422205/sourceunpack.lua>.
    lua sourceunpack.lua lib.lua
    cd out && luarocks make *.rockspec

  
RELATED WORK

  http://search.cpan.org/perldoc?lib  (Perl "use lib")
  https://gist.github.com/1342365 (Lua 'findbin' module)

COPYRIGHT

(c) 2011 David Manura.  Licensed under the same terms as Lua 5.1 (MIT license).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
  
--]]---------------------------------------------------------------------

-- lib.lua
-- (c) 2011 David Manura.  Licensed under the same terms as Lua 5.1 (MIT license).

local M = {_TYPE='module', _NAME='lib', _VERSION='0.1.20111203'}

local sep = package.config:sub(3,3)

function M.split(paths)
  local t = {}
  paths:gsub('[^%' .. sep .. ']+', function(s) t[#t+1] = s end)
  return t
end

function M.join(paths) return table.concat(paths, sep) end

local function _append(a, b) return (a=='' or b=='') and a..b or a..sep..b end
local function _prepend(a, b) return _append(b, a) end

M.path = {'<dir>/?.lua', '<dir>/?/init.lua'}
M.cpath = {'<dir>/?.so', '<dir>/?.dll'}

function _insert(dir, op)
  dir = dir:gsub('[/\\]$', '') -- omit any trailing slash
  local formats = M
  for _, which in ipairs{'path', 'cpath'} do
    local more = ''
    for _, pat in ipairs(formats[which] or {}) do
      local finalpat = pat:gsub('%<dir%>', dir)
      more = _append(more, finalpat)
    end
    package[which] = op(package[which], more)
  end
end

function M.append(dir)  _insert(dir, _append) end
function M.prepend(dir) _insert(dir, _prepend) end

function M.newrequire(...)
  local dirs = {...}
  return function(name)
    local oldpath, oldcpath = package.path, package.cpath
    for i=#dirs,1,-1 do M.prepend(dirs[i]) end
    local mod, err = pcall(require, name)
    package.path, package.cpath = oldpath, oldcpath
    if not mod then error(err) end
    return mod
  end
end

setmetatable(M, {__call = function(_, dir) return M.prepend(dir) end})

return M

---------------------------------------------------------------------

--[[ FILE lua-lib-$(_VERSION)-1.rockspec

package = 'lua-lib'
version = '$(_VERSION)-1'
source = {
  url = 'https://raw.github.com/gist/1342319/$(GITID)/lib.lua',
  --url = 'https://raw.github.com/gist/1342319/lib.lua', -- latest raw
  --url = 'https://gist.github.com/gists/1342319/download', -- latest archive
  md5 = '$(MD5)'
}
description = {
  summary = 'Simple insertion of directories in package search paths.',
  detailed =
    'Simple insertion of directories in package search paths.',
  license = 'MIT/X11',
  homepage = 'https://gist.github.com/1342319',
  maintainer = 'David Manura'
}
dependencies = {
  'lua >= 5.1' -- including 5.2
}
build = {
  type = 'builtin',
  modules = {
    ['lib'] = 'lib.lua'
  }
}

--]]---------------------------------------------------------------------


--[[ FILE test.lua

local M = require 'lib'

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

-- test append
package.path = ''; package.cpath = ''
M.append('foo')
checkeq(package.path, P'foo/?.lua;foo/?/init.lua')
checkeq(package.cpath, P'foo/?.so;foo/?.dll')
M.append('bar')
checkeq(package.path, P'foo/?.lua;foo/?/init.lua;bar/?.lua;bar/?/init.lua')
checkeq(package.cpath, P'foo/?.so;foo/?.dll;bar/?.so;bar/?.dll')

-- test prepend
package.path = ''; package.cpath = ''
M.prepend('foo')
checkeq(package.path, P'foo/?.lua;foo/?/init.lua')
checkeq(package.cpath, P'foo/?.so;foo/?.dll')
M.prepend('bar')
checkeq(package.path, P'bar/?.lua;bar/?/init.lua;foo/?.lua;foo/?/init.lua')
checkeq(package.cpath, P'bar/?.so;bar/?.dll;foo/?.so;foo/?.dll')

-- test prepend shorthand
package.path = ''
M 'foo'
checkeq(package.path, P'foo/?.lua;foo/?/init.lua')

-- test newrequire
require 'file_slurp'.writefile('tmp135.x', 'return {}')
M.path = {'<dir>/?.x'}
local require2 = M.newrequire('.')
local X = require2 'tmp135'
assert(X)
os.remove 'tmp135.x'

print 'OK'

--]]---------------------------------------------------------------------
