-- Completion handling
package.cpath = package.cpath .. ';../thirdparty/lua-linenoise/?.so'
package.path  = package.path  .. ';../?.lua'

local L     = require 'linenoise'
local utils = require 'utils'
local compl = { ctbl = nil }

function compl.ycli_complete(c, s)
    local cp    = compl.ctbl
    local line  = '' -- curr line
    local pw    = '' -- prev word
    local used  = {} -- dont show'em again
    local words = utils.getwords(utils.trim(s))

    local i = 1
    while i <= #words do
       w = words[i]
       if cp[w] then
           if type(cp[w]) == 'table' then -- full word and in table
               cp = cp[w] -- advance
           else
               used[w] = true -- filter out
           end
           line = line..' '..w
           if not (cp.__container and w == cp.__container) then -- Not right after a container
               i = i + 1 -- XXX: to incr loop invariant we need while() instead of for()
               w = words[i]
               if w then -- a value entered (non nil word)
                   line = line..' '..w
               else
                   local h = cp['__help_'..words[i-1]]
                   if not h then h = cp['__help_'..cp.__key] end -- default to key's help (FIXME)
                   print('\r\n Required: '..h)
                   L.addcompletion(c, utils.trim(line) .. ' ')
                   return -- force input
               end
           end
       else
           pw = w -- prev unfinished word
       end
       i = i + 1
    end
    if type(cp) == 'table' then
        if pw and utils.trim(pw) ~= '' then
            for k,_ in pairs(cp) do
                if k:match('^'..pw) then -- only those which match the user pfx
                    L.addcompletion(c, utils.trim(line..' '..k))
                end
            end
        else
            for k,_ in pairs(cp) do
                if not k:match('^__') and k ~= cp.__key and (not used[k]) then -- skip internal fields
                    L.addcompletion(c, utils.trim(line..' '..k))
                end
            end
        end
    end
end

function compl.init(t)
    compl.ctbl = t
end

return compl
