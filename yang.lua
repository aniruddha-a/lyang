local lpeg = require 'lpeg'

local exit=os.exit

function jcat (acc, s)
    --[[
    local a = acc:gsub('"','')
    a = a:gsub("'", '')
    local b = s:gsub('"','')
    b = b:gsub("'", '')
    return a..b
    ]]
    -- Lets sanitize str before use, not here
    return acc..s
end

function domatch (data)
    local P, R, S, C, V, Cf, Cg, Sp, Cmt =
        lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.V, lpeg.Cf, lpeg.Cg, lpeg.locale().space, lpeg.Cmt
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
                                / function(...) print('ID',...) end
    local string     = _ * (P'"' * (P'\\' * P(1) + (1 - S'\\"'))^0 * P'"') +
                       _ * (P"'" * (P'\\' * P(1) + (1 - S"\\'"))^0 * P"'")
    local concat     = _ * P'+'
    local jstring    = (C(string) * concat)^0 * C(string)
    local value      = _ * (bw^1 + Cf(jstring,jcat))
                                / function(...) print('VAL',...) end
    -- We dont need captures for the foll - remove after debug
    local stmtend    = _ * C(P';') / function(...) print('END',...) end
    local obrace     = _ * C(P'{') / function(...) print('OPEN',...) end
    local cbrace     = _ * C(P'}') / function(...) print('CLOSE',...) end

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
        print("Failed to match.", "stop @:"..pos);
    else
        if n == #data then
            print("Matched entirely")
        end
    end
end

function main ()
    local data
    if arg[1] then
        local fh = io.open(arg[1])
        if fh then
            data = fh:read('*a')
            fh:close()
        else
            print("No such file: "..arg[1])
            exit(1)
        end
    end

    if not data then
        print("No data!")
        exit(1)
    else
        domatch(data)
    end
end

main()
