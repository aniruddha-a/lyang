local argp    = require 'thirdparty/argparse'
local matcher = require 'matcher'
local ast     = require 'ast'
local pp      = require 'thirdparty/pprint'

local exit  = os.exit
local args

local modules = { -- indexable by name or prefix (Note: here we load both yang module/submodule
    name   = {},
    prefix = {}
}

function main()
    matcher.run(modules, args.input, args.debug)
    for mod,tree in pairs(modules.name) do
        if args.debug > 0 then --  ( -d )
            local pfx = modules.prefix[mod] and modules.prefix[mod] or "<none>"
            print("Dumping: '".. mod.. "' (".. pfx ..")")
            ast.indent_dump(tree, args.filter and args.filter[1] or nil) -- assume 1 filter for now
        end
    end
end

function handle_args()
    local optparse = argp("yang.lua", "A YANG recognizer and validator.")
    optparse:argument("input", "Input YANG file.")
    optparse:flag("-d --debug", "Debug (once for indented-dump, twice for parser tokens)")
              :count '0-3'
              :target 'debug'
    optparse:option("-o --output", "Output format.",
                                   "(for now indented [comment stripped] dump)")
    optparse:option("-P --path", "Module/sub-module include paths.")
              :count("*")
    optparse:option("-F --filter", "Apply filters")
              :count("*")
    args = optparse:parse()
    --pp.pprint(args)
end

handle_args()
main()
