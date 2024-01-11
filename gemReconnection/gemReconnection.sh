#!/bin/bash

#there should be a better way...
repoDir=/export/vlabApps/gemReconnection/
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

usage="<model> <electronMass> <Lx> <Ly> <tEnd> <cellsX> <cellsY>"
args=7
[[ $# -ne $args ]] && echo "$0 $usage" && exit 1

model=$1
[[ "$model" != "5" && "$model" != "10" ]] && \
  echo "model was set to \"$model\", valid options are 5 or 10" && \
  exit 1

luaScript=rt-${model}m-gem.lua
original_luaScript=$repoDir/$luaScript
[[ ! -e "$original_luaScript" ]] && echo "luaScript $1 does not exist" && exit 1

electronMass=$2

#copy the script to the working directory
cp $original_luaScript $luaScript

sed -i "s/elcMass = ionMass\\/25.0/elcMass = ionMass\\/${electronMass}/" $luaScript

#Lx = 25.6 * di0
Lx=$3
sed -i "s/Lx = 25.6 \* di0/Lx = ${Lx} \* di0/" $luaScript
#Ly = 12.8 * di0
Ly=$4
sed -i "s/Ly = 12.8 \* di0/Ly = ${Ly} \* di0/" $luaScript

#tEnd = 25.0/OmegaCi0
tEnd=$5
sed -i "s/tEnd = 25.0\\/OmegaCi0/tEnd = ${tEnd}\\/OmegaCi0/" $luaScript

#cells = {64, 32}
cellsX=$6
cellsY=$7
sed -i "s/cells = {64, 32}/cells = {${cellsX}, ${cellsY}}/" $luaScript

diff $luaScript $original_luaScript #DEBUG

/export/gkeyllSoft/bin/gkyl $luaScript
