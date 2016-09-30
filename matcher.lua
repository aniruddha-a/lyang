local lpeg   = require 'lpeg'
local pp     = require 'thirdparty/pprint'
local utils  = require 'utils'
local ast    = require 'ast'
local checks = require 'checks' -- validations

local matcher = {

}

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
    local cbrace     = _ * C(P'}') / function(...) ast.add('CLOSE',...) end

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
        if n == #data then
            print("'"..name.."': Matched entirely")
            if checks.run(ast) then
                print("'"..name.."': Validated successfully ")
                return ast.tree
            else
                print("'"..name.."': "..checks.validation_errs .. " Validation errors found")
            end
        end
    end
    return nil
end

function matcher.run(modules, infile, debug)
    local data
    local name
    local tree
    local fh = io.open(infile)

    if fh then
        data = fh:read('*a')
        fh:close()
    else
        print("No such file: "..infile)
        return false
    end

    if not data then
        print("Failed to read: ".. infile)
        return false
    else
        name = utils.basename(infile):match('[^.]+')
        ast.init(name, debug > 1 and true or false)
        tree = _domatch(name, data)
        if tree then
            modules[name] = tree
        end
        if debug > 1 then -- -dd
            pp.pprint(tree)
        end
    end
end

return matcher
