return {
    -- Remove a block containing any of the below
    remove_containing = {
        ['tailf:hidden']   = 'internal',
        ['tailf:cdb-oper'] = '*'    -- star means we dont check the value
    },
    -- Drop a node
    remove_node = {
        presence = 'true'
    },
    -- Replace a node having id(LHS) with val(RHS)
    replace_nodeid = {
        ['tailf:info'] = 'description'
    },
    -- Comment out a block
    commentout = {
        list = 'forlater',
    }
}
