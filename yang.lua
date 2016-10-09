local argp    = require 'thirdparty/argparse'
local matcher = require 'matcher'
local ast     = require 'ast'

local exit  = os.exit
local args

local modules = { -- indexable by name or prefix
    name   = {},
    prefix = {}
}

function main()
    matcher.run(modules, args.input, args.debug)
    for mod,tree in pairs(modules.name) do
        if args.debug > 0 then --  -d
            print("Dumping: '".. mod.. "' ("..modules.prefix[mod]..")")
            ast.indent_dump(tree)
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
    args = optparse:parse()
    -- pp.pprint(args)
end

handle_args()
main()
