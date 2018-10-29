-- Miscellaneous utils
local utils = {
    not_yet_matched = '__lyang_NYM',
    search_paths    = {},
    mod_dirname     = nil, -- main module dir
}

function utils.trim(s) -- trim5 of lua-users
    return s:match'^%s*(.*%S)' or ''
end

function utils.getwords(s)
    local words = {}
    for w in s:gmatch('%S+') do
        table.insert(words, w)
    end
    return words
end

function utils.strip_quote(s)
    if not s then return end
    local a = s:gsub('"','')
    a = a:gsub("'", '')
    return a
end

function utils.jcat(acc, s) -- concat Java like string (with + operators)
    -- Lets sanitize str before use, not here
    return acc..s
end

function string:split(sep)
    local sep, fields = sep or ':', {}
    local pattern = string.format('([^%s]+)', sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function utils.basename(p)
    local t = p:split('/')
    if not utils.basedir then -- FIXME hack (use -P path)
        local dir = ''
        for i=1,(#t-1) do dir = dir..t[i] end
        utils.basedir = dir
    end
    return t[#t]
end

function utils.dirname(p)
    local t   = p:split('/')
    local dir = t[1]
    for i=2,(#t-1) do dir = dir..'/'..t[i] end
    if p:match('^/') then dir = '/' .. dir end
    return ( dir == '' and '.' or dir )
end

local function file_exists(name)
    local f = io.open(name,"r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function utils.find_file(mod)
    -- Check the same dir as module
    local nam = utils.mod_dirname .. '/' .. mod .. '.yang'
    if file_exists(nam) then return nam end
    --
    -- Check std modules
    local nam = 'std/' .. mod .. '.yang'
    if file_exists(nam) then return nam end

    -- Check paths in the given order
    for _,v in ipairs(utils.search_paths) do
        nam = v .. '/' .. mod .. '.yang'
        if file_exists(nam) then return nam end
    end
    print("Error: Failed to find '"..mod.."'")
    os.exit(1)
end

function utils.set_search_path(pt, mainmod)
    utils.search_paths = pt
    utils.mod_dirname  = utils.dirname(mainmod) -- set main module's dir
end

function utils.namespaced(s)
    return s:match(':') and true or false
end

-- Remove ns: part and return name
function utils.strip_ns(s)
    if utils.namespaced(s) then
        return s:split()[2] -- default delim ':'
    else
        return s
    end
end

-- Return {ns, name} tuple
function utils.split_ns(s)
    if utils.namespaced(s) then
        return s:split()[1], s:split()[2]
    else
        return s
    end
end

function utils.strip_ext (f)
    return f:gsub('.yang$', '')
end

function utils.is_abs_path(s)
    return s:match('^/') == a
end

function utils.path_components(path)
    local t={}
    for p in path:gmatch('[^/]+') do
        table.insert(t, p)
    end
    return t
end

return utils
