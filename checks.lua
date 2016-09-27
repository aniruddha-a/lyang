local checks = {
   must_have       = {},
   allowed         = {},
   validation_errs = 0,
}

checks.must_have['module']    = { 'namespace', 'prefix' }
checks.must_have['submodule'] = { 'belongs-to' }
checks.must_have['typedef']   = { 'type' }
checks.must_have['leaf']      = { 'type' }
checks.must_have['leaf-list'] = { 'type' }


checks.allowed['module'] = {
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

checks.allowed['submodule'] = {
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

checks.allowed['import'] = {
    prefix            = true,
    ['revision-date'] = true,
}

checks.allowed['belongs-to'] = {
    prefix            = true,
}

checks.allowed['include'] = {
    ['revision-date'] = true,
}

checks.allowed['revision'] = {
    description = true,
    reference   = true,
}

checks.allowed['typedef'] = {
    default      = true,
    description  = true,
    reference    = true,
    status       = true,
    type         = true,
    units        = true,
}

checks.allowed['type'] = {
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

checks.allowed['container'] = {
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

checks.allowed['must'] = {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

checks.allowed['leaf'] = {
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

checks.allowed['leaf-list'] = {
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

checks.allowed['list'] = {
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

checks.allowed['choice'] = {
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

checks.allowed['case'] = {
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

checks.allowed['anyxml'] = {
    config         = true,
    description    = true,
    ['if-feature'] = true,
    mandatory      = true,
    must           = true,
    reference      = true,
    status         = true,
    when           = true,
}

checks.allowed['grouping'] = {
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

checks.allowed['uses'] = {
    augment        = true,
    description    = true,
    ['if-feature'] = true,
    refine         = true,
    reference      = true,
    status         = true,
    when           = true,
}

checks.allowed['rpc'] = {
    description    = true,
    grouping       = true,
    ['if-feature'] = true,
    input          = true,
    output         = true,
    reference      = true,
    status         = true,
    typedef        = true,
}

checks.allowed['input'] = {
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

checks.allowed['output'] =  {
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

checks.allowed['notification'] =  {
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

checks.allowed['augment'] =  {
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

checks.allowed['identity'] =  {
    base        = true,
    description = true,
    reference   = true,
    status      = true,
}

checks.allowed['extension'] =  {
    argument    = true,
    description = true,
    reference   = true,
    status      = true,
}

checks.allowed['argument'] =  {
    ['yin-element'] = true,
}

checks.allowed['feature'] =  {
    description    = true,
    ['if-feature'] = true,
    reference      = true,
    status         = true,
}

checks.allowed['deviation'] =  {
    description = true,
    deviate     = true,
    status      = true,
}

checks.allowed['deviate'] =  {
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

checks.allowed['range'] =  {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

checks.allowed['length'] =  {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

checks.allowed['pattern'] =  {
    description       = true,
    ['error-app-tag'] = true,
    ['error-message'] = true,
    reference         = true,
}

checks.allowed['enum'] =  {
    description = true,
    reference   = true,
    status      = true,
    value       = true,
}

checks.allowed['bit'] =  {
    description = true,
    reference   = true,
    status      = true,
    position    = true,
}

function _apply_checks(id, val, t)
    local chk_list = checks.allowed[id]
    local seen = {}
    if not chk_list then
        -- print('NYI for', id)
        return
    end

    for _,k in ipairs(t.kids) do
        if not chk_list[k.id] and not k.id:match(':') then -- ignore namespaced kids
            print("Error: '"..k.id.."' cannot appear as child of '"..id.."' ("..id.." "..val..")")
            checks.validation_errs = checks.validation_errs + 1
        end
        if checks.must_have[id] then
            if not seen[k.id] then seen[k.id] = true end
        end
    end

    if checks.must_have[id] then
        for _,v in ipairs(checks.must_have[id]) do
            if not seen[v] then
                print("Error: '"..v.."' is mandatory under '"..id.."' ("..id.." "..val..")")
                checks.validation_errs = checks.validation_errs + 1
            end
        end
    end
end

function _run(t)
    for _,k in ipairs(t.kids) do
        if k.node then
            _apply_checks(k.id, k.val, k.node)
        end
    end
    for _,k in ipairs(t.kids) do
        if k.node then
            _run(k.node)
        end
    end
end

function checks.run(t)
    checks.validation_errs = 0
    _run(t)
    if checks.validation_errs > 0 then
        return false
    else
        return true
    end
end

return checks
