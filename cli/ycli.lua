
package.cpath = package.cpath .. ';../thirdparty/lua-linenoise/?.so'
package.path  = package.path  .. ';../?.lua'

local L     = require 'linenoise'
local utils = require 'utils'

if not arg[1] then print [[ usage: ycli <cli-file> ]] os.exit(1) end

local ctbl = dofile(arg[1])
if not ctbl or type(ctbl) ~= 'table' then
    print("Failed to load cli-file")
    os.exit(1)
end

function ycli_complete(c, s)
    local cp   = ctbl
    local line = ''
    local pw   = ''

    words = utils.getwords(utils.trim(s))
    local i = 1
    while i <= #words do
       w = words[i]
       if cp[w] then
           cp = cp[w]
           line = line..' '..w
           if cp.__key then -- skip list key
               i = i + 1 -- XXX: to incr loop invariant we need while() instead of for()
               w = words[i]
               if w then
                   line = line..' '..w
               else
                   print('\r\n Required: '..cp['__help_'..cp.__key])
                L.addcompletion(c, utils.trim(line))
                return
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
                if not k:match('^__') and k ~= cp.__key then -- skip internal fields
                    L.addcompletion(c, utils.trim(line..' '..k))
                end
            end
        end
    end

end

function show_banner()
    local bannerfile='cli/.banner'
    os.execute('cat '..bannerfile)
end

function main()
    local prompt   = "lycli> "
    local histfile = '.clihist.txt'

    L.loadhistory(histfile)
    L.setcompletion(ycli_complete)

    local line = L.linenoise(prompt)
    while line do
        line = utils.trim(line)
        local n = #line
        if n > 0 then
            L.historyadd(line)
            print('\r\n Adding ['..line..']')
            L.historysave(histfile)
        end
        --[[
        if line:sub(n,n) == '?' then
        dumpcompletions(line:sub(1, n-1))
        else
        local f = gfn[line]
        if f then f(line) else print 'Invalid/Incomplete command' end
        L.historyadd(line)
        end
        ]]
        line = L.linenoise(prompt)
    end
end

show_banner()
main()
