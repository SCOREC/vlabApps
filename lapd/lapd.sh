#!/bin/bash

#there should be a better way...
repoDir=/export/vlabApps/lapd/
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=$repDir/LAPD3D5Mg2_coarseGrid.lua
eval "$(conda shell.bash hook)"
conda activate /export/gkeyllSoft/postgkyl
[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1
/export/gkeyllSoft/bin/gkyl $luaScript
