-- AST handling
local ast = {
        tree = nil,
        name = nil, -- basename of the file (module name)
        prefixes = {} -- map import prefix to actual module name
}
local utils  = require 'utils'
local checks = require 'checks'

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
function _indent_f(t, nsp, filter)
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
                    _indent_f(k.node, nsp + 4, filter)
                    print(sp:rep(nsp)..'}')
                end
            end

            if comm_started then print("*/") comm_started = nil end

            ::continue::
        end -- foreach kid
    end
end

function _expand_inplace_augment(t)
    --[[
    --for every augment in the list found
    --check where they belong (search the loaded modules list)
    --and expand inline
    --]]

end

-- We first search with the NS prefix as-is (if the name of the module
-- and the prefix with which it was imported matches, then this
-- will work) If not, we change the prefix to the actual module name
-- and search again.
function _get_grouping(name)
    local g = utils.strip_quote(name)
    local grp = checks.groupings[g]

    if grp then return grp end

    local ns, n = utils.split_ns(name)
    g = ast.prefixes[ns]..':'..n
    print ("$$$ changed : ", name , g)
    grp = checks.groupings[g]

    if grp then return grp end

    grp = checks.groupings[n]
    if grp then return grp end

    assert(grp, 'No such group found: '.. name)
end

-- First lets completely expand all 'uses', whether within 'grouping's or
-- outside. Once we are done with this phase, we are safe to remove 'grouping's
-- as we wont need their _content_ anymore
function _expand_inplace_uses(t)
    if t.kids then
        local has_more_uses = false
        repeat
            local newkids = {}
            has_more_uses = false
            for i,k in ipairs(t.kids) do
                if k.id == 'uses' then
                    cg = _get_grouping(k.val)
                    for p,q in pairs(cg.kids) do -- copy over in the same order as found in grouping
                        table.insert(newkids, q)
                        if q.id == 'uses' then has_more_uses = true end
                    end
                else
                    table.insert(newkids, k)
                end
            end
            t.kids = newkids
        until has_more_uses == false

        for _,k in ipairs(t.kids) do
            if k.node then
                _expand_inplace_uses(k.node)
            end
        end
    end
end

function _remove_groupings(t)
    if t.kids then
	-- reverse walk - to remove safely (even consecutive items)
	for i=#t.kids,1,-1 do
	    if t.kids[i].id == 'grouping' then
		table.remove(t.kids, i)
	    end
	end

        for _,k in ipairs(t.kids) do
            if k.node then
                _remove_groupings(k.node)
            end
        end
    end
end

function is_config(t)
    for _,k in ipairs(t) do
        if k.id == 'config' and k.val =='false' then
            return false
        end
    end
    return true
end

-- we are skipping choice/case/when/must here!
function to_cli(i, v, p)
    if i == 'key' then
        return "__key = '".. v .. "'"
    elseif i == 'description' then
        return "['__help_"..p.."'] = '"..utils.strip_quote(v).."'"
    elseif i == 'list' or i == 'container' then
        return "['"..v.."']"
    elseif i == 'leaf' or i == 'leaf-list' then
        return "['"..v.."'] = '' " -- TODO type handle for leaf/leaf-list
    end
    return nil
end

function _cli_dump(t, pval, nsp)
    local sp = ' '
    local val, line

    if t.kids and is_config(t.kids) then -- kids can be empty blocks like: container C {}
        for _,k in ipairs(t.kids) do
            val = (k.val and k.val or '')
            line = to_cli(k.id, val, pval)
            if line then
                if k.id == 'container' then
                    print(sp:rep(nsp).. line ..' = {')
                    print(sp:rep(nsp).. "\t __container = '"..k.val.."',")
                    _cli_dump(k.node, val, nsp + 4)
                    print(sp:rep(nsp)..'},')
                elseif k.id == 'list' then
                    print(sp:rep(nsp).. line ..' = {')
                    _cli_dump(k.node, val, nsp + 4)
                    print(sp:rep(nsp)..'},')
                else
                    print(sp:rep(nsp).. line ..',')
                    if k.node then _cli_dump(k.node, val, nsp + 4) end
                end
            else
                if k.node then _cli_dump(k.node, val, nsp + 4) end
            end
        end
    end
end

function ast.indent_dump(t, ff)
    if ff then
        local f = dofile(ff)
        return _indent_f(t, 0, f)
    else
        return _indent(t, 0)
    end
end

function ast.cli_dump(t)
    return _cli_dump(t, nil, 0)
end

function _store_import_prefixes(t)
    local pfx, modname
    for _,k in ipairs(t.kids) do
        if k.id == 'module' or k.id == 'submodule' then
            for _,s in ipairs(k.node.kids) do
                if s.id == 'import' then
                    modname = utils.strip_quote(s.val)
                    if s.node.kids[1].id == 'prefix' then -- XXX:assume first entry is prefix?
                        pfx = utils.strip_quote(s.node.kids[1].val)
                        ast.prefixes[pfx] = modname
                    end
                end
            end
        end
    end
end

function ast.expand_inplace(t)
    _store_import_prefixes(t)
    _expand_inplace_uses(t)
    _remove_groupings(t)
    -- TODO: expand includes  as well ? (submodules will then be empty/removed?)
    _expand_inplace_augment(t)
end

return ast
