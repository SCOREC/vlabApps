#!/bin/bash
luaScript=buneman-5m.lua
eval "$(conda shell.bash hook)"
conda activate /export/gkeyllSoft/postgkyl
python generate-buneman-5m.py $luaScript "$@"
[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1
/export/gkeyllSoft/bin/gkyl $luaScript
