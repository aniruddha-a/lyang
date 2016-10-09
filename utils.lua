local utils = {}

function utils.trim(s) -- trim5 of lua-users
    return s:match'^%s*(.*%S)' or ''
end

function utils.strip_quote(s)
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
    return t[#t]
end

return utils
