-- AST handling
local ast = {
        tree = nil,
        name = nil, -- basename of the file (module name)
        prefixes = {} -- map import prefix to actual module name
}
local utils  = require 'utils'
local checks = require 'checks'
local colors = require 'thirdparty/ansicolors'

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

function _remove_elements(t, elem)
    if t.kids then
	-- reverse walk - to remove safely (even consecutive items)
	for i=#t.kids,1,-1 do
	    if t.kids[i].id == elem then
		table.remove(t.kids, i)
	    end
	end

        for _,k in ipairs(t.kids) do
            if k.node then
                _remove_elements(k.node, elem)
            end
        end
    end
end

--[[
    Augment cannot contain augment - so this can be processed
    before expanding groupings
--]]
function _expand_inplace_augment(mm)
    if not mm.kids then return end

    local augments = {}
    local t = mm.kids[1].node -- Directly get into the module/submodule's contents
    for _, k in ipairs(t.kids) do
        if k.id == 'augment' then
            table.insert(augments, { path = k.val, contents = k.node.kids }) -- path can be repeated in multiple augments, cant use as key
        end
    end

    -- XXX: Do we have to first expand grouping at this stage
    -- before attempting augment path processsing?
    -- What if the path that we are trying to find, wont exist
    -- unless grouping expansion has been completed !?

    if #augments == 0 then return end

    for _,data in ipairs(augments) do
        local path = data.path
        local ptbl = utils.strip_quote(path):split('/') -- get path components
        local augt = data.contents
        local idx  = 1
        local t    = mm.kids[1].node                    -- Directly get into the module/submodule's contents (only main module path are processed)
        while t and idx <= #ptbl do                     -- for as many levels in the path
            local ns, pname = utils.split_ns(ptbl[idx]) -- path components maybe namespaced
            if not pname then pname = ns end            -- when no namespace
            found = false
            for _, k in ipairs(t.kids) do
                if k.val == pname and (k.id == 'container' or k.id == 'list') then -- augment can be only under a content node
                    idx = idx + 1
                    t = k.node
                    found = true
                    break
                end
            end
            if not found then
                -- Not present in the current main module that we are processing
                print(colors("%{magenta}Augment path: %{bright}".. path.. "%{reset} not found in current set"))
                t = nil
                break
            end
        end
        if t and idx == #ptbl+1 then
            for _,v in pairs(augt) do
                table.insert(t.kids, v)
                v.parent = t
            end
        end
    end
end

-- A sub-module can be 'include'd in more than one file
local included_already = {}
function _not_yet_included (m)
    if included_already[m] then
        return false
    else
        included_already[m] = true
        return true
    end
end

function _expand_inplace_includes (mm)
    if not mm.kids then return end

    local t = mm.kids[1].node -- Directly get into the module/submodule's contents
    for _, k in ipairs(t.kids) do
        if k.id == 'include' and _not_yet_included(k.val) then
            local im = get_tree(k.val) -- get included module/submodule tree
            local it = im.kids[1].node  -- get into mod/submod contents
            for _, j in ipairs(it.kids) do
                if j.id == 'container' or j.id == 'list' then -- Expand only content nodes from includes to main module
                    table.insert(t.kids, j)
                end
            end
        end
    end
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
    print(colors("%{cyan}Canonicalize namespace: %{bright}".. name.. "%{reset} %{cyan} => ".. g .."%{reset}"))
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

function _path_dump_f(t, path, filter)
    local skip = false
    if filter.config_only and not is_config(t.kids) then
        skip = true
    end
    if not skip then
        for _,k in ipairs(t.kids) do
            if k.id == 'container' or k.id == 'list' then
                _path_dump_f(k.node, path..'/'..k.val, filter)
            else
                if k.id == 'leaf' or k.id == 'leaf-list' then
                    if filter.show_only then
                        if k.id == filter.show_only then
                            print(path..'/'..k.val)
                        end
                    else
                        print(path..'/'..k.val)
                    end
                end
            end
        end
    end
end

function _path_dump(t, path)
    for _,k in ipairs(t.kids) do
        if k.id == 'container' or k.id == 'list' then
            _path_dump(k.node, path..'/'..k.val)
        else
            if k.id == 'leaf' or k.id == 'leaf-list' then
                print(path..'/'..k.val)
            end
        end
    end
end

function ast.path_dump(t, ff)
    if ff then
        local f = dofile(ff)
        return _path_dump_f(t.kids[1].node, '', f)
    else
        return _path_dump(t.kids[1].node, '')
    end
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
    _expand_inplace_includes(t)
    _expand_inplace_uses(t) -- groupings
    _remove_elements(t, 'grouping')
    _expand_inplace_augment(t)
    _remove_elements(t, 'augment')
    _remove_elements(t, 'include')
end

return ast
