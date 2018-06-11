-- Main CLI (via linenoise)
package.cpath = package.cpath .. ';../thirdparty/lua-linenoise/?.so'
package.path  = package.path  .. ';../?.lua'

local L     = require 'linenoise'
local utils = require 'utils'
local compl = require 'compl'

local prompt   = "lycli> "
local histfile = '/tmp/.lyclihist'

if not arg[1] then print [[ usage: ycli <cli-file> ]] os.exit(1) end

local ctbl = dofile(arg[1])
if not ctbl or type(ctbl) ~= 'table' then
    print("Failed to load cli-file")
    os.exit(1)
else
    compl.init(ctbl)
end

function show_banner()
    local basedir    = utils.dirname(arg[0])
    local bannerfile = basedir ..'/.banner'
    os.execute('cat '..bannerfile)
end

function main()
    L.loadhistory(histfile)
    L.setcompletion(compl.ycli_complete)

    local line = L.linenoise(prompt)
    while line do
        line = utils.trim(line)
        local n = #line
        --[[
        if n > 0 then
        end
        ]]
        if line:sub(n,n) == '?' then
            l = line:sub(1, n-1)
            compl.list_compls(l)
        else
            L.historyadd(line)
            print('\r\n Adding ['..line..']')
            L.historysave(histfile)
            --local f = gfn[line]
            --if f then f(line) else print 'Invalid/Incomplete command' end
        end
        line = L.linenoise(prompt)
    end
end

show_banner()
main()
