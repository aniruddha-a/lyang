-- The LPeg based recognizer/matcher
local lpeg   = require 'lpeg'
local pp     = require 'thirdparty/pprint'
local utils  = require 'utils'
local ast    = require 'ast'
local checks = require 'checks' -- validations
local colors = require 'thirdparty/ansicolors'

local matcher = { }

local function perror(msg)
    print('Error: '..msg)
end

function _domatch(name, data)
    local P, R, S, C, V   = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.V
    local Cf, Cg, Sp, Cmt = lpeg.Cf, lpeg.Cg, lpeg.locale().space, lpeg.Cmt
    local pos        = 0
    local chk        = Cmt(P(true), function(s,p,...) pos = p; return p; end)
    local ccomment   = P'/*' * (1 - P'*/')^0 * P'*/'
    local cppcomment = P'//' * (1 - P'\n')^0
    local comment    =  (ccomment + cppcomment)
    local _          =  (Sp + comment )^0
    local digit      =  P'-'^-1 * R'09' + P'.' --  -ve/decimal/range
    local letter     =  R('az', 'AZ') + S'_-'
    local alnum      =  (letter + digit)
    local bw         =  (alnum + S'/:*![]=')   --   at least some junk barewords!
    local identifier =  letter * alnum^0
    local ns_id      = _ * C((identifier * P':')^-1 * identifier) * chk
                                / function(...) ast.add('ID',...) end
    local string     = _ * (P'"' * (P'\\' * P(1) + (1 - S'\\"'))^0 * P'"') +
                       _ * (P"'" * (P'\\' * P(1) + (1 - S"\\'"))^0 * P"'")
    local concat     = _ * P'+'
    local jstring    = (C(string) * concat)^0 * C(string)
    local value      = _ * (bw^1 + Cf(jstring, utils.jcat))
                                / function(...) ast.add('VAL',...) end
    -- We dont need captures for the foll - remove after debug
    local stmtend    = _ * C(P';') / function(...) ast.add('END',...) end
    local obrace     = _ * C(P'{') / function(...) ast.add('OPEN',...) end
    local cbrace     = _ * C(P'}') * _ / function(...) ast.add('CLOSE',...) end

    local yang = P({
        "block",
        block = ns_id * value^-1 * (stmtend + (
                                    obrace *
                                       V"block"^0 *
                                    cbrace
                                    )),
    })
    local n = yang:match(data)
    if not n then
        print("Failed to match '"..name.."'.", "stop @:"..pos);
    else
        if n >= #data then
            print(colors('%{bright}'..name..':%{green} Matched entirely%{reset}'))
            -- Load only the import/includes, so that we can continue further matching
            checks.load_sub(ast, matcher.modules)
            return ast.tree
        end
    end
    perror("'"..name.."': Failed to match")
    return nil
end

local function _get_modname(infile)
    return utils.basename(infile):match('[^.]+')
end

local function _read_file(infile)
    local fh = io.open(infile)
    local data

    if fh then
        data = fh:read('*a')
        fh:close()
        return data
    else
        perror("No such file: "..infile)
        return nil
    end
end

function matcher.run(modules, args)

    matcher.modules = modules

    local infile  = args.input
    local debug   = args.debug

    local modname = _get_modname(infile)
    local data    = _read_file(infile)
    local tree    = nil

    if not data then
        perror("Failed to read: ".. infile)
        return false
    end
    --
    -- Match and load the main module
    ast.init(modname, debug > 2 and true or false)
    tree = _domatch(modname, data)
    if tree then
        if modules.name[modname] ~= nil then
            perror("There is already a module with name: "..modname)
        else
            modules.name[modname] = tree
        end
    end
    if debug > 2 --[[ -ddd ]] then pp.pprint(tree) end

    -- Check if we had imports/includes and they need to be matched as well
    -- XXX: Keep a sorted, local list of module names so that we dont mess
    --      up the original, with insertions during walk

    ::recheck::

    local modarr={}
    for k,v in pairs(modules.name) do
        if v == utils.not_yet_matched then
            table.insert(modarr, k)
        end
    end
    if next(modarr) == nil then
        print(colors('%{blue}MATCHING COMPLETE%{reset}'))
        return
    end
    table.sort(modarr) -- predictable order
    for _,mod in ipairs(modarr) do
        t = modules.name[mod]
        print(colors('%{bright}'..modname..'%{reset}:%{yellow} Requires '..mod..'%{reset}'))
        ast.init(mod, debug > 2 and true or false)
        data = _read_file(utils.find_file(mod))
        if data then
            tree = _domatch(mod, data)
            if tree then
                modules.name[mod] = tree  -- as per Lua its ok to modify while walk, no new additions thou
                if debug > 2 then pp.pprint(tree) --[[ -ddd ]] end
            end
        else
            perror("Failed to read: ".. utils.find_file(mod))
        end
    end

    goto recheck -- I know, E.W. Dijkstra would not like this! :-/

end

return matcher
