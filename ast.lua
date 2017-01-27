local ast = {
        tree = nil,
        name = nil, -- basename of the file (module name)
}
local utils = require 'utils'

function ast.getnode(p)
    return { kids={}, parent=p }
end

function ast.init(name, dbg)
    ast.tree  = ast.getnode(nil)
    ast.cur   = ast.tree
    ast.name  = name
    ast.debug = dbg
end

local id, val = nil, nil

function ast.add(type,...)
    local tok = {...}
    local cur = ast.cur
    local node

    if ast.debug then print(type,...) end

    if type == 'ID' then
        id  = utils.trim(tok[1])
        val = nil
    elseif type == 'VAL' then
        val = utils.trim(tok[1])
    elseif type == 'END' then
        table.insert(cur.kids, { ['id']=id, ['val']=val, ['node']=nil } )
        id, val = nil, nil
    elseif type == 'OPEN' then
        node = ast.getnode(cur)
        table.insert(cur.kids, { ['id']=id, ['val']=val, ['node']=node } )
        cur           = node
        id, val, node = nil, nil, nil
    elseif type == 'CLOSE' then
        cur = cur.parent
    else
        print 'Err'
    end
    ast.cur = cur
end

-- Plain indent
function _indent(t, nsp)
    local sp = ' '
    local val

    if t.kids then              -- kids can be empty blocks like: container C {}
        for _,k in ipairs(t.kids) do
            val = (k.val and k.val or '')

            -- put the concat ops - make it like orig yang
            if val and (val:match('"') or val:match("'")) then
                val = val:gsub('"%s+"', '" + "')
                val = val:gsub("'%s+'", "' + '")
            end

            if not k.node then
                print(sp:rep(nsp).. k.id ..' '.. val ..';')
            else
                print(sp:rep(nsp).. k.id ..' '.. val ..' {')
                _indent(k.node, nsp + 4)
                print(sp:rep(nsp)..'}')
            end
        end
    end
end

-- With filters
function _indent2(t, nsp, filter)
    local sp = ' '
    local val, comm_started
    local fremov, fdrop, freplace, fcomment

    if t.kids then              -- kids can be empty blocks like: container C {}
        for _,k in ipairs(t.kids) do
            val = (k.val and k.val or '')

            if filter.remove_node then
                fdrop = filter.remove_node[k.id]
                if fdrop and fdrop == utils.strip_quote(k.val) then
                    -- print("Drop (", k.id, k.val, ")")
                    goto continue
                end
            end

            if filter.replace_nodeid then
                freplace = filter.replace_nodeid[k.id]
                if freplace then
                    -- print("Replace (", k.id, " => ", freplace, ")")
                    k.id = freplace
                end
            end

            -- put the concat ops - make it like orig yang
            if val and (val:match('"') or val:match("'")) then
                val = val:gsub('"%s+"', '" + "')
                val = val:gsub("'%s+'", "' + '")
            end

            if filter.commentout then
                fcomment = filter.commentout[k.id] or nil
                if fcomment and fcomment == utils.strip_quote(k.val) then
                    -- print("Start-comment (", k.id, k.val, ")")
                    print("/*")
                    comm_started = true
                end
            end

            -- write out the kids (if present) or the stmt terminator
            if not k.node then
                print(sp:rep(nsp).. k.id ..' '.. val ..';')
            else
                local skip = false
                -- walk thru the kids to see if we need to skip this block
                for _,kids in pairs(k.node.kids) do
                    if filter.remove_containing then
                        fremov = filter.remove_containing[kids.id]
                        if fremov then
                            if fremov == '*' then
                                skip = true
                                -- print("Skip-any (", k.id, val, ")")
                            else
                                if fremov == utils.strip_quote(kids.val) then
                                    skip = true
                                    -- print("Skip (", k.id, val, ")")
                                end
                            end
                        end
                    end
                end
                if not skip then


                    print(sp:rep(nsp).. k.id ..' '.. val ..' {')
                    _indent2(k.node, nsp + 4, filter)
                    print(sp:rep(nsp)..'}')

                end
            end

            if comm_started then print("*/") comm_started = nil end

            ::continue::
        end -- foreach kid
    end
end

function ast.indent_dump(t, ff)
    if ff then
        local f = dofile(ff)
        return _indent2(t, 0, f)
    else
        return _indent(t, 0)
    end
end

return ast
