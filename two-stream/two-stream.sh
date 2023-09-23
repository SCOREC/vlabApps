#!/bin/bash

#there should be a better way...
repoDir=/export/vlabApps/two-stream
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=two-stream-5m.lua
eval "$(conda shell.bash hook)"
conda activate /export/gkeyllSoft/postgkyl
python $repoDir/generate-two-stream.py $luaScript "$@" --model 5-moment
[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1
/export/gkeyllSoft/bin/gkyl $luaScript
