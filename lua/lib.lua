-- lib.lua
-- (c) 2011-2012 David Manura.  Licensed under Lua 5.1 terms (MIT license).

local M = {_TYPE='module', _NAME='lib', _VERSION='0.2.0.20120426'}

local sep = package.config:sub(3,3)

function M.split(paths)
  local t = {}
  paths:gsub('[^%' .. sep .. ']+', function(s) t[#t+1] = s end)
  return t
end

function M.join(paths) return table.concat(paths, sep) end

local function _after(a, b) return (a=='' or b=='') and a..b or a..sep..b end
local function _before(a, b) return _after(b, a) end

M.path_form = {'<dir>/?.lua', '<dir>/?/init.lua'}
M.cpath_form = {}
local has_so  = (package.cpath..';'):match'%?%.so;'
local has_dll = (package.cpath..';'):match'%?%.dll;'
local has_none = not(has_so or has_dll)
if has_so  or has_none then table.insert(M.cpath_form, '<dir>/?.so')  end
if has_dll or has_none then table.insert(M.cpath_form, '<dir>/?.dll') end

function _insert(dir, op, formats)
  local bad = '[%?%'..sep..']'
  assert(not dir:match(bad), 'dir contains a ? or ;') -- cannot be escaped
  dir = dir:gsub('[/\\]$', '') -- omit any trailing slash
  dir = dir:gsub('^<bin>', function()
    return require 'findbin'.bin
  end)
  formats = formats or M
  for _, which in ipairs{'path', 'cpath'} do
    local more = ''
    for _, pat in ipairs(formats[which..'_form'] or {}) do
      local finalpat = pat:gsub('%<dir%>', dir)
      more = _after(more, finalpat)
    end
    package[which] = op(package[which], more)
  end
end

function M.after(dir)  _insert(dir, _after, M) end
function M.before(dir) _insert(dir, _before, M) end

local function _toarray(o)
  return type(o) == 'string' and {o} or o
end

local function _normalize_args(...)
  local opt = type(...) == 'table' and ... or {...}
  local before = _toarray(opt.before or opt)
  local after = _toarray(opt.after or {})
  local path_form = _toarray(opt.path_form or M.path_form)
  local cpath_form = _toarray(opt.cpath_form or M.cpath_form)
  local formats = {path_form=path_form, cpath_form=cpath_form}
  return {before=before, after=after,
          path_form=path_form, cpath_form=cpath_form, formats=formats}
end

local function _apply_paths(a)
  for i=#a.before,1,-1 do _insert(a.before[i], _before, a.formats) end
  for i=1,#a.after     do _insert(a.after[i],  _after,  a.formats) end
end

function M.newrequire(...)
  local a = _normalize_args(...)
  return function(name)
    local oldpath, oldcpath = package.path, package.cpath
    local mod, err = pcall(function()  -- may assert
      _apply_paths(a)
      return require(name)
    end)
    package.path, package.cpath = oldpath, oldcpath
    if not mod then error(err) end
    return mod
  end
end

local function __call(_, ...)
  local a = _normalize_args(...)
  _apply_paths(a)
end

setmetatable(M, {__call = __call})

return M

