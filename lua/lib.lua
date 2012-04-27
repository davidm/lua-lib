-- lib.lua
-- (c) 2011-2012 David Manura.  Licensed under Lua 5.1 terms (MIT license).

local M = {_TYPE='module', _NAME='lib', _VERSION='0.1.1.20120407'}

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
M.cpath = {}
local has_so  = (package.cpath..';'):match'%?%.so;'
local has_dll = (package.cpath..';'):match'%?%.dll;'
local has_none = not(has_so or has_dll)
if has_so  or has_none then table.insert(M.cpath, '<dir>/?.so')  end
if has_dll or has_none then table.insert(M.cpath, '<dir>/?.dll') end


function _insert(dir, op, formats)
  assert(not dir:match'%?', 'dir contains a ?') -- cannot be escaped
  dir = dir:gsub('[/\\]$', '') -- omit any trailing slash
  dir = dir:gsub('^<bin>', function()
    return require 'findbin'.bin
  end)
  formats = formats or M
  for _, which in ipairs{'path', 'cpath'} do
    local more = ''
    for _, pat in ipairs(formats[which] or {}) do
      local finalpat = pat:gsub('%<dir%>', dir)
      more = _append(more, finalpat)
    end
    package[which] = op(package[which], more)
  end
end

function M.append(dir)  _insert(dir, _append, M) end
function M.prepend(dir) _insert(dir, _prepend, M) end

local function _toarray(o)
  return type(o) == 'string' and {o} or o
end

function M.newrequire(...)
  local opt = type(...) == 'table' and ... or {...}
  local before = _toarray(opt.before or opt)
  local after = _toarray(opt.after or {})
  local path = _toarray(opt.path or M.path)
  local cpath = _toarray(opt.cpath or M.cpath)
  local formats = {path=path, cpath=cpath}
  return function(name)
    local oldpath, oldcpath = package.path, package.cpath
    local mod, err = pcall(function()  -- may assert
      for i=#before,1,-1 do _insert(before[i], _prepend, formats) end
      for i=#after,1,-1 do _insert(after[i], _append, formats) end
      return require(name)
    end)
    package.path, package.cpath = oldpath, oldcpath
    if not mod then error(err) end
    return mod
  end
end

setmetatable(M, {__call = function(_, dir) return M.prepend(dir) end})

return M

