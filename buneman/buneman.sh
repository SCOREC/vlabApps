#!/bin/bash
luaScript=buneman-5m.lua
python genreate-buneman-5m.py "$@"
[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1
/export/gkeyllSoft/bin/gkyl $luaScript
