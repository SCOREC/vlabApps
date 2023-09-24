#!/bin/bash

#there should be a better way...
repoDir=/export/vlabApps/weibel/
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=weibel-1x2v-10m.lua
eval "$(conda shell.bash hook)"
conda activate /export/gkeyllSoft/postgkyl
python $repoDir/generate-weibel-1x2v-10m.py $luaScript "$@"
[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1
/export/gkeyllSoft/bin/gkyl $luaScript
