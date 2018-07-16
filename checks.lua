-- Validation - Enforce RFC6020 checks
local utils = require 'utils'

local checks = {
   validation_errs = 0,
   modname         = nil, -- Name of the module/submodule we are processing
   groupings       = {},
   augments        = {},
   belongs_to      = nil
}

local must_have_subs    = {}
local allowed_subs      = {}
local additional_checks = {}
local mark              = {}

local function perror(msg)
    print('Error: '.. "'"..checks.modname.."': " ..msg)
    checks.validation_errs = checks.validation_errs + 1
end

local function pnotice(msg)
    print("'"..checks.modname.."': Note: "..msg)
end

-- Module and revision checks
local function check_module(t)
    if t.val ~= checks.modname then
        perror("Module name ("..t.val..") and file name ("..checks.modname
                    ..") should match")
    end
    local subs = t.node.kids
    local rev  = {}
    local header_seen, linkage_seen, meta_seen, revision_seen = false, false, false, false

    for _,k in ipairs(subs) do
        if k.id == 'namespace' or k.id == 'prefix' or k.id == 'belongs-to' then -- submodule chk also
            if linkage_seen or meta_seen or revision_seen then
                if t.id == 'module' then
                    perror(t.id .. " must begin with namespace/prefix ("..t.id.." "..t.val..")")
                else
                    perror(t.id .." must begin with belongs-to ("..t.id.." "..t.val..")")
                end
            end
            header_seen = true
        end
        if k.id == 'import' or k.id == 'include' then
            if meta_seen or revision_seen then
                perror("'import'/'include' statements should be before"..
                      " 'revision'/meta statements (module "..t.val..")")
            end
            linkage_seen = true
        end
        if k.id == 'revision' then
            revision_seen = true
            local val = utils.strip_quote(k.val)
            if not val:match('^%d%d%d%d[-]%d%d[-]%d%d$') then
                perror("revision date should be of the form: YYYY-MM-DD ("..k.val..")")
            end
            table.insert(rev, val) -- create a revisions table
        end
    end
    -- Walk through all the revisions
    for i = 1,#rev do
        if rev[i+1] and rev[i] < rev[i+1] then
            perror("revisions should be in reverse chronological order ("
            ..rev[i+1].." before "..rev[i]..")")
        end
    end
end

-- Called after the initial match of module/submodule to load the import/includes
local function add_to_match_list(t)
    local name = utils.strip_quote(t.val)
    if type(checks.modules.name[name]) == 'table' then
        return -- Already matched
    end
    checks.modules.name[name] = utils.not_yet_matched

    if not t.node then return end  -- No kids, e.g: include submod;

    local subs = t.node.kids
    for _,k in ipairs(subs) do -- If the modules were imported with a different prefix ... TODO
        if k.id == 'prefix' then
            local pfx = utils.strip_quote(k.val) -- FIXME: if 'name' was already pres
            checks.modules.prefix[pfx] = utils.not_yet_matched
        end
    end
end

local function assert_ver1(t)
    if utils.strip_quote(t.val) ~= '1' then
        perror("Only YANG version 1 supported (version has to be '1')")
    end
end

local function store_grouping(t)
    checks.groupings[t.val] = t.node -- normal entry
    if checks.belongs_to then
        checks.groupings[checks.belongs_to..':'..t.val] = t.node -- Parent NS prefixed entry
    else
        checks.groupings[checks.modname..':'..t.val] = t.node -- NS prefixed entry
    end
end

local function store_augment(t)
    checks.augments[t.val] = t.node
end

local function ensure_key_on_cfg(t)
    local subs        = t.node.kids
    local is_config   = true
    local key_present = false

    for _,k in ipairs(subs) do -- foreach sub-statements
        if k.id == 'config' and utils.strip_quote(k.val) == 'false' then
            is_config = false
        elseif k.id == 'key' then
            key_present = true
        end
    end

    if is_config and not key_present then
        local node  = t.val
        local level = 1

        -- Keep moving up the tree, and check if there were a 'config false'
        -- so that we can ensure this list represents operational data
        t = t.node.parent
        while t do
            for _,k in ipairs(t.kids) do
                if k.id == 'config' and utils.strip_quote(k.val) == 'false' then
                    pnotice("'list "..node.."' - operational (inherit from level "..level..")")
                    return
                end
            end
            t     = t.parent
            level = level + 1
        end

        perror("'key' mandatory for lists representing config ('".. node .."')")
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
additional_checks['module']       = check_module
additional_checks['submodule']    = check_module

additional_checks['yang-version'] = assert_ver1

additional_checks['list']         = ensure_key_on_cfg

-- Make a note/store location of..
mark['grouping'] = store_grouping
mark['augment']  = store_augment

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
    base                 = true, -- FIXME: only when the type is identityref !
    ['fraction-digits']  = true, -- FIXME: only when type is decimal64
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
    description   = true, -- Not in RFC, coz we perform checks post grouping expansion!
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
    description   = true, -- Not in RFC, coz we perform checks post grouping expansion!
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

    --[[
    if not chk_list then
         print('NYI for', id)
        return
    end
    ]]

    -- No children or no list of substatements to chk
    if not t or not chk_list then
        goto only_additional
    end

    for _,k in ipairs(t.kids) do
        if not chk_list[k.id] and not k.id:match(':') then -- ignore namespaced kids
            perror("'"..k.id.."' cannot appear as child of '"..id.."' ("
                        ..id.." ".. (val or '<>') ..")")
        end
        if must_have_subs[id] then
            if not seen[k.id] then seen[k.id] = true end
        end
    end

    if must_have_subs[id] then
        for _,v in ipairs(must_have_subs[id]) do
            if not seen[v] then
                perror("'"..v.."' is mandatory under '"..id.."' ("..id.." "..val..")")
            end
        end
    end

::only_additional::

    if additional_checks[id] then
        additional_checks[id](n)
    end
end

function _run(t)
    if not t.kids then return end -- TODO: How!? scary!
    for _,k in ipairs(t.kids) do
        _apply_checks(k)
    end
    for _,k in ipairs(t.kids) do
        if k.node then
            _run(k.node)
        end
    end
end

function checks.run(tree, name)
    local t        = tree
    checks.modname = name

    checks.validation_errs = 0
    _run(t)
    if checks.validation_errs > 0 then
        return false
    else
        return true
    end
end

function _mark_nodes(t)
    local id = t.id
    if mark[id] then
        mark[id](t)
    end
end

function _do_mark(t)
    for _,k in ipairs(t.kids) do
        _mark_nodes(k)
    end
    for _,k in ipairs(t.kids) do
        if k.node then
            _do_mark(k.node)
        end
    end
end

-- Initial (minimal) load/check - this is required to tell the
-- matcher which included submodules/imports are to be matched
-- Also, stores locations of grouping/augments
function checks.load_sub(ast, modules)
    local t           = ast.tree
    checks.modname    = ast.name
    checks.modules    = modules
    checks.belongs_to = nil
    local name        = nil

    for _,k in ipairs(t.kids) do
        if k.id == 'module' or k.id == 'submodule' then
            name = utils.strip_quote(k.val)
            for _,s in ipairs(k.node.kids) do
                if s.id == 'import' or s.id == 'include' then
                    add_to_match_list(s)
                elseif s.id == 'prefix' then
                    checks.modules.prefix[name] = utils.strip_quote(s.val)
                elseif s.id == 'belongs-to' then
                    checks.belongs_to = utils.strip_quote(s.val)
                end
            end
            goto mark_nodes
        end
    end
    ::mark_nodes::
    _do_mark(t)
end

return checks
