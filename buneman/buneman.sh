#!/bin/bash

#there should be a better way...
repoDir=/export/vlabApps/buneman/
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=buneman-5m.lua
eval "$(conda shell.bash hook)"
conda activate /export/gkeyllSoft/postgkyl
python $repoDir/generate-buneman-5m.py $luaScript "$@"
[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1
/export/gkeyllSoft/bin/gkyl $luaScript
