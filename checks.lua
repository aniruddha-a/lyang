local checks = {
   must_have = {},
   allowed   = {}
}

checks.must_have['module'] = { 'namespace', 'prefix' }
checks.must_have['leaf'] = { 'type' }


checks.allowed['module'] = {
    namespace    = true,
    prefix       = true,
    organization = true,
    import       = true,
    include      = true,
    description  = true,
    revision     = true,
    grouping     = true,
    typedef      = true,
    container    = true,
    augment      = true,
}

checks.allowed['leaf'] = {
    description = true,
    type        = true,
    pattern     = true,
    length      = true,
    range       = true,
    default     = true,
    units       = true,
}

function _apply_checks(id, t)
    local chk_list = checks.allowed[id]
    local seen = {}
    if not chk_list then
        -- print('NYI for', id)
        return
    end

    for _,k in ipairs(t.kids) do
        if not chk_list[k.id] and not k.id:match(':') then
            print("Error: '"..k.id.."' cannot appear as child of '"..id.."'")
        end
        if not seen[k.id] then seen[k.id] = true end
    end
    for _,v in ipairs(checks.must_have[id]) do
        if not seen[v] then
            print("Error: '"..v.."' is mandatory under '"..id.."'")
        end
    end
end

function checks.run(t)
    for _,k in ipairs(t.kids) do
        if k.node then
            _apply_checks(k.id, k.node)
        end
    end
    for _,k in ipairs(t.kids) do
        if k.node then
            checks.run(k.node)
        end
    end
end

return checks
