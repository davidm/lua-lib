LUA MODULE

  lib v$(_VERSION) - Simple insertion of directories in package search paths.
  
SYNOPSIS

  -- Basic usage: adding directories to module search paths.
  require 'lib' '/foo/bar'
    -- prepends given directory to package.path and package.cpath.
  require 'lib'.prepend '/foo/bar' -- same as above
  require 'lib'.append '/foo/baz'  -- appends directory instead
  require 'lib' '<bin>/../lib/lua' -- prepends directory '../lib/lua'
                       -- relative to the currently executing script
                       -- (requires 'findbin' [2] module)
  require 'lpeg' -- this now searches in above paths.

  -- Localized changes to module search paths (avoids side-effects).
  do
    local require = require 'lib'.newrequire('/foo/bar', '/bar/foo')
    local BAZ = require 'baz'  -- searches inside /foo/bar & /bar/foo
  end
  local QUX = require 'qux'  -- does not search inside /foo/bar & /bar/foo

  -- Utilty functions (assuming "lua test/example.lua").
  local LIB = require 'lib'
  LIB.split(package.path)
     --> {'/foo/bar/?.lua', '/foo/bar/?/init.lua',
          'test/../lib/lua/?.lua', 'test/../lib/lua/?/init.lua', 
          . . . , '/foo/baz/?.lua', '/foo/baz/?/init.lua'}
  
  -- Custom template formats.
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
    Template patterns in `LIB.template` are used to build the templates.
    `dir` may be prefixed by the text `<bin>`, which will be replaced with
    the directory of the currently executing script (this requires the
    `findbin` [2] module).
    Examples:
    
      require 'lib'.prepend'/foo/bar'
      require 'lib'.prepend'<bin>/../lib/lua'
      
    Function raises an error if `dir` contains a `?`.
    
  LIB.append(dir)
  
    Same as `LIB.prepend` but appends rather than prepends.

  LIB (dir)
  
    This is the same as `LIB.prepend(dir)`.  Examples:
    
      require 'lib' '/foo/bar'
      require 'lib' '<bin>/../lib/lua'
    
  LIB.split(paths)
  
    Splits package search string `paths` (in the format expected by
    `package.path` or `package.searchpath`) into an array of path templates:
    
      LIB.split('/foo/bar/?.so;/baz/?.so') --> {'/foo/bar/?.so', '/baz/?.so'}
    
  LIB.path / LIB.cpath
  
    This is a table containing the formats of templates inserted into
    `package.path` and `package.cpath` by `LIB.prepend` and
    `LIB.append`.  For example, default values are
  
      LIB.path = {'<dir>/?.lua', '<dir>/?/init.lua'}
      LIB.cpath = {'<dir>/?.so', '<dir>/?.dll'}

    Any '<dir>' in these templates is replaced by the path being added.
    
    When this module is first loaded, `LIB.cpath` will contain 
    '<dir>/?.so' if the package.cpath originally contained any '?.so' entries,
    and likewise for '?.dll'.  However, both forms will be added if
    `package.cpath` has neither.
    
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
  
  Paths are by default prepended rather than appended to allow
  locally installed modules to override any globally installed modules.
  (Perl 'lib' does likewise.)
  
  .luac files are not by default included in LIB.path (same as in luaconf.h).  It
  may be argued that compiled bytecode just as well be given a .lua extension.
  
  `LIB.prepend`, `LIB.append`, and `LIB.path/cpath` cause global side-effects.
  After all, `require` utilizes `package.path` and `package.cpath` globals.
  
  Directory names cannot contain '?' or be prefixed by '<bin>'.  For future
  compatibility, avoid directory names with '<' and '>' characters.

DEPENDENCIES

  Lua 5.1 or 5.2.
  Optionally, the 'findbin' module [2].
  
HOME PAGE

  https://github.com/davidm/lua-lib
  
DOWNLOAD/INSTALL

  To install using LuaRocks:
  
    luarocks install lib

  Otherwise, download <https://github.com/davidm/lua-lib>.
  
  You may simply copy lib.lua into your LUA_PATH.
  
  Optionally:
  
    make test
    make install  (or make install-local)  -- installed into LuaRocks
    make remove  (or make remove-local) -- removed from LuaRocks
  
RELATED WORK

  [1] http://search.cpan.org/perldoc?lib  (Perl "use lib")
  [2] https://github.com/davidm/lua-find-bin (Lua 'findbin' module)

COPYRIGHT

(c) 2011-2012 David Manura.  Licensed under the same terms as Lua 5.1 (MIT license).

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
  
