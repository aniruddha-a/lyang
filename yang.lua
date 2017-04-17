-- The Main driver
local argp    = require 'thirdparty/argparse'
local matcher = require 'matcher'
local ast     = require 'ast'
local pp      = require 'thirdparty/pprint'
local checks  = require 'checks'
local utils   = require 'utils'

local args

local modules = { -- indexable by name / prefix (Note: we load both module/submodule here
    name   = {},
    prefix = {}
}

function dump_tree()
    for mod,tree in pairs(modules.name) do
        local pfx = modules.prefix[mod] and modules.prefix[mod] or "<none>"
        print("Dumping: '".. mod.. "' (".. pfx ..")")
        ast.indent_dump(tree, args.filter and args.filter[1]
                                           or nil) -- assume 1 filter file for now
    end
end

function do_validate()
    for mod,tree in pairs(modules.name) do
        ast.expand_inplace(tree)
        if checks.run(tree, mod, modules) then
            print("'"..mod.."': Validated successfully ")
        else
            print("'"..mod.."': "..checks.validation_errs .. " Validation errors found")
        end
    end
end

function dump_cli()
    if args.output ~= 'cli' then
        return
    end

    local old_print = nil
    if args.file then
        old_print=print
        io.output(args.file) -- redirect stdout
        print=function(...) io.write(table.concat({...},' '),'\n') end
    end
    print("-- lyang 0.1: from "..args.input.." @ "..os.date())
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
    utils.set_search_path(args.path, args.input)
    matcher.run(modules, args)
    if args.debug == 1 then -- ( -d )
        dump_tree() -- unexpanded tree
    end
    do_validate()
    if args.debug == 2 then -- ( -dd )
        dump_tree() -- expanded tree
    end
    dump_cli()  -- validation/expansion shud have completed
end

function handle_args()
    local optparse = argp("yang.lua", "A YANG recognizer and validator.")
    optparse:argument("input", "Input YANG file.")
    optparse:flag("-d --debug", "Debug ( once for indented-yang;\n\t "..
                                        "twice for expanded-yang;\n\t "..
                                        "thrice for parser-tokens & internal-table dump)")
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
