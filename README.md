# LYang

Lua [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/) based [YANG](https://tools.ietf.org/html/rfc6020) recognizer and validator.

# Required packages:

    $ sudo apt-get install lua5.2 lua-lpeg

# Utils/debug

- Using [pprint](https://github.com/jagt/pprint.lua) for debugging.
- Using [lua-linenoise](https://github.com/hoelzro/lua-linenoise) for line edit/CLI completion.
- Using [ansicolors](https://github.com/kikito/ansicolors.lua) for colored status output.
- For standalone exe [luastatic](https://github.com/ers35/luastatic)

> Note: using compiled version of lua-linenoise (compiled with Lua 5.2).
> If the installation on host is different - needs recompilation.

> Note: For standalone exe, we need Lua or LuaJIT .a and headerfiles,
> Also, the lpeg static lib, which is copied in the thirdparty/ dir.
