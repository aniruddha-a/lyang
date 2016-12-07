return {
    remove_containing = {
        ['tailf:hidden']   = 'internal',
        ['tailf:cdb-oper'] = '*'    -- star means we dont check the value
    },
    remove_node = {
        presence = 'true'
    },
    replace_nodeid = {
        ['tailf:info'] = 'description'
    },
}
