local utils = {}

function utils.trim(s) -- trim5 of lua-users
    return s:match'^%s*(.*%S)' or ''
end

function utils.jcat(acc, s)
    --[[
    local a = acc:gsub('"','')
    a = a:gsub("'", '')
    local b = s:gsub('"','')
    b = b:gsub("'", '')
    return a..b
    ]]
    -- Lets sanitize str before use, not here
    return acc..s
end

function _indent(t, nsp)
    local sp = ' '
    local val
    if t.kids then
        for _, k in ipairs(t.kids) do
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

function utils.indent_dump(t)
    return _indent(t, 0)
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
