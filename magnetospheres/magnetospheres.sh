#!/bin/bash

#there should be a better way...
repoDir=/export/vlabApps/magnetospheres
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=magnetosphere-3d-10m.lua
eval "$(conda shell.bash hook)"
conda activate /export/gkeyllSoft/postgkyl
python $repoDir/generate-magnetosphere-3d-10m.py $luaScript "$@"
[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1
/export/gkeyllSoft/bin/gkyl $luaScript
