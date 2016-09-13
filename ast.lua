local ast = {
        tree = nil,
        name = nil,
        meta = nil -- TODO (uses/import/grouping etc?)
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

return ast
