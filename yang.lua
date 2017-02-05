-- The Main driver
local argp    = require 'thirdparty/argparse'
local matcher = require 'matcher'
local ast     = require 'ast'
local pp      = require 'thirdparty/pprint'

local args

local modules = { -- indexable by name / prefix (Note: we load both module/submodule here
    name   = {},
    prefix = {}
}

function dump_debug()
    for mod,tree in pairs(modules.name) do
        if args.debug > 0 then --  ( -d )
            local pfx = modules.prefix[mod] and modules.prefix[mod] or "<none>"
            print("Dumping: '".. mod.. "' (".. pfx ..")")
            ast.indent_dump(tree, args.filter and args.filter[1] or nil) -- assume 1 filter for now
        end
    end
end

function dump_cli()
    if args.output ~= 'cli' then
        return
    end
    local old_print=nil
    if args.file then
        old_print=print
        io.output(args.file)
        print=function(...) io.write(table.concat({...},' '),'\n') end
    end
    print("return {")
    print("  show = { interim = {}}, commit = true, exit = true,\n") -- std cmds
    print("  set = {\n   __container = 'set',")
    for mod,tree in pairs(modules.name) do
        ast.cli_dump(tree)
    end
    print("  }\n}")
    if old_print then
        print=old_print
        print("Written to: "..args.file)
    end
end

function main()
    matcher.run(modules, args.input, args.debug)
    dump_debug()
    dump_cli()
end

function handle_args()
    local optparse = argp("yang.lua", "A YANG recognizer and validator.")
    optparse:argument("input", "Input YANG file.")
    optparse:flag("-d --debug", "Debug (once for indented-dump, twice for parser tokens)")
              :count '0-3'
              :target 'debug'
    optparse:option("-o --output", "Output format (for now: 'cli') ")
    optparse:option("-f --file", "Write to file")
    optparse:option("-P --path", "Module/sub-module include paths.")
              :count("*")
    optparse:option("-F --filter", "Apply filters")
              :count("*")
    args = optparse:parse()
    --pp.pprint(args)
end

handle_args()
main()
