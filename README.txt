LUA MODULE

  lib v$(_VERSION) - Simple insertion of directories in package search paths.
  
SYNOPSIS

  -- Basic usage: adding directories to package.path & package.cpath.
  require 'lib' '/foo/bar' -- prepends given directory
  require 'lib'.before '/foo/bar' -- same as above
  require 'lib'.after '/foo/baz'  -- appends instead
  require 'lib' '<bin>/../lib/lua' -- prepends directory relative to
        -- currently executing script (requires 'findbin' [2] module)
  require 'lpeg' -- this now searches in above paths.

  -- Custom template formats.
  require 'lib'.path_form = {'<dir>/?.luac', '<dir>/.lua'}
  require 'lib' '/foo/bar'
  print(package.path) --> '/foo/bar/?.luac;/foo/bar/?.lua; . . .'

  -- Combined function call:
  require 'lib' {
    before = {'/foo/bar', '/bar/foo'},
    after = '/foo/baz',
    path_form = {'<dir>/?.luac', '<dir>/.lua'},
    cpath_form= '<dir>/.so'
  }

  -- Localized changes to module search paths (reduces side-effects).
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

DESCRIPTION

  Adding a directory to the package search paths (`package.path` and
  `package.cpath`) can be a chore.  There can be multiple template
  variants to add such as '<dir>/?.lua' and '<dir>/?/init.lua'.
  This module simplifies that.

API

  LIB ( [dir...] )
  
    Prepends templates for each directory `dir` to `package.path` and
    `package.cpath`.
    Template patterns in `LIB.template` are used to build the templates.
    `dir` may be prefixed by the text `<bin>`, which will be replaced with
    the directory of the currently executing script (this requires the
    `findbin` [2] module).  Examples:
    
      require 'lib' '/foo/bar'
      require 'lib' '<bin>/../lib/lua'
      require 'lib' ('/foo/bar', '/bar/foo')
      
    Caveat: Function raises an error if `dir` contains a `?` or path
    separator (`package.config:sub(3,3)`, typically ';').

  LIB.before( [dir...] )

    This is the same as `LIB (dir)`.  Examples:
    
      require 'lib'.before'/foo/bar'
      require 'lib'.before'<bin>/../lib/lua'      

  LIB.after( [dir...] )
  
    Same as `LIB.before` but appends rather than prepends.

  LIB.path_form / LIB.cpath_form
  
    This is a table containing the formats of templates inserted into
    `package.path` and `package.cpath` by `LIB.before` and
    `LIB.after`.  For example, default values are
  
      LIB.path_form = {'<dir>/?.lua', '<dir>/?/init.lua'}
      LIB.cpath_form = {'<dir>/?.so', '<dir>/?.dll'}

    Any '<dir>' in these templates is replaced by the path being added.
    
    When this module is first loaded, `LIB.cpath_form` will contain 
    '<dir>/?.so' if the package.cpath originally contained any '?.so' entries,
    and likewise for '?.dll'.  However, both forms will be added if
    `package.cpath` has neither.

  LIB { before={ [dir...] }, after={ [dir...] },
        path_form={ [format...] }, cpath_form={ [format...] }  }
	
    This combines the above functions into a single function call.
    Note, however, that the `path_form` and `cpath_form` will only apply to
    the current function call and are not set globally in `LIB.path_form`
    and `LIB.cpath_form`.
    
    All parameters are optional.  If a string is passed
    to a parameter expecting an arrray, it is converted to an array of size 1.
    [dir...] and { [dir...] } are shorthand for { before = { [dir...] }}.

  LIB.split(paths)
  
    Splits package search string `paths` (in the format expected by
    `package.path` or `package.searchpath`) into an array of path templates:
    
      LIB.split('/foo/bar/?.so;/baz/?.so') --> {'/foo/bar/?.so', '/baz/?.so'}

  LIB.newrequire( [dir...] ) -> require
  LIB.newrequire{ before={ [dir...] }, after={ [dir...] },
                  path_form={ [format...] }, cpath_form={ [format...] }  }
                -> require
  
    This builds a `require` like function that prepends the given directories
    to the search paths, invokes the original `require` function, and then
    restores the search paths.  The arguments are the same as for the
    `LIB()` function.
     
      do
        local require = require 'lib'.newrequire('/foo/bar', '/bar/foo')
        local BAZ = require 'baz'  -- searches inside /foo/bar & /bar/foo
      end
      local QUX = require 'qux'  -- does not search inside /foo/bar & /bar/foo
      
      -- more complex
      local require = require 'lib'.newrequire{before={'/a', '/b'}, after='/c',
	                   path_form='<dir>/?.lua', cpath_form='<dir>/?.so'}

    Note: The new paths will also be visible if require is recursively invoked
    from the module being loaded.
    Any formats are expanded at the time of the `require` call, not the
    construction of the `require` function.
    
DESIGN NOTES

  '<dir>/?.lua' preceeds '<dir>/?/init.lua' as in luaconf.h.  This in
  theory allows a module to be named 'init'.
  
  Paths are by default prepended rather than appended to allow
  locally installed modules to override any globally installed modules.
  (Perl 'lib' does likewise.)
  
  .luac files are not by default included in LIB.path_form (same as in
  luaconf.h).
  It may be argued that compiled bytecode just as well be given a .lua
  extension.
  
  `LIB.before`, `LIB.after`, and `LIB.path_form/cpath_form` cause global
  side-effects.
  After all, `require` utilizes `package.path` and `package.cpath` globals.
  
  Directory names cannot contain '?' or path separator (typically ';')
  or be prefixed by '<bin>'.  For future
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
