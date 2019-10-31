function do_llist(N) 
    while N.node.parent do 
        print(N.val)
        N = N.node.parent
    end
end
return {
   no_dump = true,
   acton_node = {
       ['leaf-list'] = do_llist
   }
}
