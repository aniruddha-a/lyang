local checks = {
   validation_errs = 0,
   modname         = nil,
}

must_have_subs, allowed_subs, additional_checks  = {}, {}, {}

local function print_error(msg)
    print('Error: '..msg)
    checks.validation_errs = checks.validation_errs + 1
end

-- Module and revision checks
local function check_module(t)
    if t.val ~= checks.modname then
        print_error("Module name ("..t.val..") and file name ("..checks.modname
                    ..") should match")
    end
    local subs = t.node.kids
    local header_seen, linkage_seen, meta_seen, revision_seen = false, false, false, false
    local rev ={}

    for _,k in ipairs(subs) do
        if k.id == 'namespace' or k.id == 'prefix' or k.id == 'belongs-to' then -- submodule chk also
            if linkage_seen or meta_seen or revision_seen then
                if t.id == 'module' then
                    print_error(t.id .. " must begin with namespace/prefix ("..t.id.." "..t.val..")")
                else
                    print_error(t.id .." must begin with belongs-to ("..t.id.." "..t.val..")")
                end
            end
            header_seen = true
        end
        if k.id == 'import' or k.id == 'include' then
            if meta_seen or revision_seen then
                print_error("'import'/'include' statements should be before"..
                      " 'revision'/meta statements (module "..t.val..")")
            end
            linkage_seen = true
        end
        if k.id == 'revision' then
            revision_seen = true
            if not k.val:match('^%d%d%d%d[-]%d%d[-]%d%d$') then
                print_error("revision date should be of the form: YYYY-MM-DD ("..k.val..")")
            end
            table.insert(rev, k.val)
        end
    end
    for i = 1,#rev do
        if rev[i+1] and rev[i] < rev[i+1] then
            print_error("revisions should be in reverse chronological order ("
            ..rev[i+1].." before "..rev[i]..")")
        end
    end
end

-- ******************** List/table of all checks ****************

-- Mandatory substatements
must_have_subs['module']    = { 'namespace', 'prefix' }
must_have_subs['submodule'] = { 'belongs-to' }
must_have_subs['typedef']   = { 'type' }
must_have_subs['leaf']      = { 'type' }
must_have_subs['leaf-list'] = { 'type' }

-- Additional checks which do not fit under other categories
additional_checks['module'] = check_module
additional_checks['module'] = check_module

--[[
additional_checks['import'] = add_to_match_list
additional_checks['include'] = add_to_match_list
actions['grouping'] = expand_grouping
actions['augment'] = expand_augment
]]

-- Allowed substatements (only these can appear under its parent [other than namespaced ones])
allowed_subs['module'] = {
    anyxml           = true,
    augment          = true,
    choice           = true,
    contact          = true,
    container        = true,
    description      = true,
    deviation        = true,
    extension        = true,
    feature          = true,
    grouping         = true,
    identity         = true,
    import           = true,
    include          = true,
    leaf             = true,
    ['leaf-list']    = true,
    list             = true,
    namespace        = true,
    notification     = true,
    organization     = true,
    prefix           = true,
    reference        = true,
    revision         = true,
    rpc              = true,
    typedef          = true,
    uses             = true,
    ['yang-version'] = true,
}

allowed_subs['submodule'] = {
    anyxml           = true,
    augment          = true,
    ['belongs-to']   = true,
    choice           = true,
    contact          = true,
    container        = true,
    description      = true,
    deviation        = true,
    extension        = true,
    feature          = true,
    grouping         = true,
    identity         = true,
    import           = true,
    include          = true,
    leaf             = true,
    ['leaf-list']    = true,
    list             = true,
    notification     = true,
    organization     = true,
    reference        = true,
    revision         = true,
    rpc              = true,
    typedef          = true,
    uses             = true,
    ['yang-version'] = true,
}

allowed_subs['import'] = {
    prefix            = true,
    ['revision-date'] = true,
}

allowed_subs['belongs-to'] = {
    prefix            = true,
}

allowed_subs['include'] = {
    ['revision-date'] = true,
}

allowed_subs['revision'] = {
    description = true,
    reference   = true,
}

allowed_subs['typedef'] = {
    default      = true,
    description  = true,
    reference    = true,
    status       = true,
    type         = true,
    units        = true,
}

allowed_subs['type'] = {
    bit                  = true,
    default              = true,
    enum                 = true,
    length               = true,
    path                 = true,
    pattern              = true,
    range                = true,
    ['require-instance'] = true,
    type                 = true,
}

allowed_subs['container'] = {
    anyxml         = true,
    choice         = true,
    config         = true,
    container      = true,
    description    = true,
    grouping       = true,
    ['if-feature'] = true,
    leaf           = true,
    ['leaf-list']  = true,
    list           = true,
    must           = true,
    presence       = true,
    reference      = true,
    status         = true,
    typedef        = true,
    uses           = true,
    when           = true,
}

allowed_subs['must'] = {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

allowed_subs['leaf'] = {
    config         = true,
    default        = true,
    description    = true,
    ['if-feature'] = true,
    mandatory      = true,
    must           = true,
    reference      = true,
    status         = true,
    type           = true,
    units          = true,
    when           = true,
}

allowed_subs['leaf-list'] = {
    config           = true,
    description      = true,
    ['if-feature']   = true,
    ['max-elements'] = true,
    ['min-elements'] = true,
    must             = true,
    ['ordered-by']   = true,
    reference        = true,
    status           = true,
    type             = true,
    units            = true,
    when             = true,
}

allowed_subs['list'] = {
    anyxml           = true,
    choice           = true,
    config           = true,
    container        = true,
    description      = true,
    grouping         = true,
    ['if-feature']   = true,
    key              = true,
    leaf             = true,
    ['leaf-list']    = true,
    list             = true,
    ['max-elements'] = true,
    ['min-elements'] = true,
    must             = true,
    ['ordered-by']   = true,
    reference        = true,
    status           = true,
    typedef          = true,
    unique           = true,
    uses             = true,
    when             = true,
}

allowed_subs['choice'] = {
    anyxml         = true,
    case           = true,
    config         = true,
    container      = true,
    default        = true,
    description    = true,
    ['if-feature'] = true,
    leaf           = true,
    ['leaf-list']  = true,
    list           = true,
    mandatory      = true,
    reference      = true,
    status         = true,
    when           = true,
}

allowed_subs['case'] = {
    anyxml         = true,
    choice         = true,
    container      = true,
    description    = true,
    ['if-feature'] = true,
    leaf           = true,
    ['leaf-list']  = true,
    list           = true,
    reference      = true,
    status         = true,
    uses           = true,
    when           = true,
}

allowed_subs['anyxml'] = {
    config         = true,
    description    = true,
    ['if-feature'] = true,
    mandatory      = true,
    must           = true,
    reference      = true,
    status         = true,
    when           = true,
}

allowed_subs['grouping'] = {
    anyxml        = true,
    choice        = true,
    container     = true,
    description   = true,
    grouping      = true,
    leaf          = true,
    ['leaf-list'] = true,
    list          = true,
    reference     = true,
    status        = true,
    typedef       = true,
    uses          = true,
}

allowed_subs['uses'] = {
    augment        = true,
    description    = true,
    ['if-feature'] = true,
    refine         = true,
    reference      = true,
    status         = true,
    when           = true,
}

allowed_subs['rpc'] = {
    description    = true,
    grouping       = true,
    ['if-feature'] = true,
    input          = true,
    output         = true,
    reference      = true,
    status         = true,
    typedef        = true,
}

allowed_subs['input'] = {
    anyxml        = true,
    choice        = true,
    container     = true,
    grouping      = true,
    leaf          = true,
    ['leaf-list'] = true,
    list          = true,
    typedef       = true,
    uses          = true,
}

allowed_subs['output'] =  {
    anyxml        = true,
    choice        = true,
    container     = true,
    grouping      = true,
    leaf          = true,
    ['leaf-list'] = true,
    list          = true,
    typedef       = true,
    uses          = true,
}

allowed_subs['notification'] =  {
    anyxml         = true,
    choice         = true,
    container      = true,
    description    = true,
    grouping       = true,
    ['if-feature'] = true,
    leaf           = true,
    ['leaf-list']  = true,
    list           = true,
    reference      = true,
    status         = true,
    typedef        = true,
    uses           = true,
}

allowed_subs['augment'] =  {
    anyxml         = true,
    case           = true,
    choice         = true,
    container      = true,
    description    = true,
    ['if-feature'] = true,
    leaf           = true,
    ['leaf-list']  = true,
    list           = true,
    reference      = true,
    status         = true,
    uses           = true,
    when           = true,
}

allowed_subs['identity'] =  {
    base        = true,
    description = true,
    reference   = true,
    status      = true,
}

allowed_subs['extension'] =  {
    argument    = true,
    description = true,
    reference   = true,
    status      = true,
}

allowed_subs['argument'] =  {
    ['yin-element'] = true,
}

allowed_subs['feature'] =  {
    description    = true,
    ['if-feature'] = true,
    reference      = true,
    status         = true,
}

allowed_subs['deviation'] =  {
    description = true,
    deviate     = true,
    status      = true,
}

allowed_subs['deviate'] =  {
    config           = true,
    default          = true,
    mandatory        = true,
    ['max-elements'] = true,
    ['min-elements'] = true,
    must             = true,
    type             = true,
    unique           = true,
    units            = true,
}

allowed_subs['range'] =  {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

allowed_subs['length'] =  {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

allowed_subs['pattern'] =  {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

allowed_subs['enum'] =  {
    description = true,
    reference   = true,
    status      = true,
    value       = true,
}

allowed_subs['bit'] =  {
    description = true,
    reference   = true,
    status      = true,
    position    = true,
}

function _apply_checks(n)
    local id       = n.id
    local val      = n.val
    local t        = n.node
    local chk_list = allowed_subs[id]
    local seen     = {}

    if not chk_list then
        -- print('NYI for', id)
        return
    end

    for _,k in ipairs(t.kids) do
        if not chk_list[k.id] and not k.id:match(':') then -- ignore namespaced kids
            print_error("'"..k.id.."' cannot appear as child of '"..id.."' ("
                        ..id.." "..val..")")
        end
        if must_have_subs[id] then
            if not seen[k.id] then seen[k.id] = true end
        end
    end

    if must_have_subs[id] then
        for _,v in ipairs(must_have_subs[id]) do
            if not seen[v] then
                print_error("'"..v.."' is mandatory under '"..id.."' ("..id.." "..val..")")
            end
        end
    end

    if additional_checks[id] ~= nil then
        additional_checks[id](n)
    end
end

function _run(t)
    for _,k in ipairs(t.kids) do
        if k.node then
            _apply_checks(k)
        end
    end
    for _,k in ipairs(t.kids) do
        if k.node then
            _run(k.node)
        end
    end
end

function checks.run(ast)
    local t        = ast.tree
    checks.modname = ast.name

    checks.validation_errs = 0
    _run(t)
    if checks.validation_errs > 0 then
        return false
    else
        return true
    end
end

return checks
