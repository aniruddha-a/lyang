-- The Main driver
local argp    = require 'thirdparty/argparse'
local matcher = require 'matcher'
local ast     = require 'ast'
local pp      = require 'thirdparty/pprint'
local colors  = require 'thirdparty/ansicolors'
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
        print(colors("%{cyan}Dumping: %{bright}".. mod.. "%{reset} %{cyan}(".. pfx ..")%{reset}"))
        ast.indent_dump(tree, args.filter and args.filter[1]
                                           or nil) -- assume 1 filter file for now
    end
end

function dump_main(mm)
    for mod,tree in pairs(modules.name) do
        if utils.basename(utils.strip_ext(mm)) == mod then
            local pfx = modules.prefix[mod] and modules.prefix[mod] or "<none>"
            print(colors("%{cyan}Expanded: %{bright}".. mod.. "%{reset} %{cyan}(".. pfx ..")%{reset}"))
            ast.indent_dump(tree, args.filter and args.filter[1]
                                               or nil) -- assume 1 filter file for now
        end
    end
end

function do_validate()
    local sortedmods = {}
    for m,_ in pairs(modules.name) do
        table.insert(sortedmods, m)
    end
    table.sort(sortedmods)
    for i, mod in ipairs(sortedmods) do
        tree = modules.name[mod]
        ast.expand_inplace(tree)
        if checks.run(tree, mod, modules) then
            print(colors('%{bright}'..mod..'%{reset}: %{green}Validated successfully%{reset}'))
        else
            print(colors('%{bright}'..mod..'%{reset}: %{red}'..checks.validation_errs..' Validated errors found%{reset}'))
        end
    end
end

function dump_cli()
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

function dump_path()
    local old_print = nil
    if args.file then
        old_print=print
        io.output(args.file) -- redirect stdout
        print=function(...) io.write(table.concat({...},' '),'\n') end
    end
    for mod,tree in pairs(modules.name) do
        ast.path_dump(tree, args.filter and args.filter[1] or nil)
    end
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
    --[[ test
    for mod,t in pairs(modules.name) do
        if t == utils.not_yet_matched then
            print("XXX", mod,": Not matched")
        end
    end
    ]]
    do_validate()
    if args.debug == 2 then -- ( -dd )
        dump_tree() -- expanded modules
    end
    if args.expand then
        dump_main(args.input) -- Only main module
    end
    if args.output == 'cli' then
        dump_cli()  -- validation/expansion shud have completed
    elseif args.output == 'path' then
        dump_path()
    end
end

function handle_args()
    local optparse = argp("yang.lua", "A YANG recognizer and validator.")
    optparse:argument("input", "Input YANG file.")
    optparse:flag("-d --debug", "Debug ( once for indented-yang;\n\t "..
                                        "twice for expanded-yang;\n\t "..
                                        "thrice for parser-tokens & internal-table dump)")
              :count '0-3'
    optparse:flag("-E --expand", "Expand and show only main Module.")
              :count '0-1'
    optparse:option("-o --output", "Output format ('cli' | 'path') ")
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
