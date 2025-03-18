#!/bin/bash

set -x
echo $GKYL
echo $PGKYL_CONDA_ENV
echo $CONDA
set +x
[[ ! -e "$GKYL" ]] && echo "path to gkyl executable $GKYL does not exist" && exit 1
#[[ ! -d "$PGKYL_CONDA_ENV" ]] && echo "path to pgkyl conda environment $PGKYL_CONDA_ENV does not exist or is not a directory" && exit 1
#[[ ! -e "$CONDA" ]] && echo "path to conda binary $CONDA does not exist" && exit 1

repoDir=$(dirname $(readlink -f $0))
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

$GKYL $luaScript

### post processing
#eval "$(${CONDA} shell.bash hook)"
#conda activate $PGKYL_CONDA_ENV
#pgkyl rt-*m-gem_field_1.bp sel -c 0,1,2,3,4,5 pl -x x -y y --diverging -a --figsize 12,3 --saveas 'fields.png'
#pgkyl rt-*m-gem_elc_1.bp pl -x x -y y -a --figsize 12,3 --saveas 'electrons.png'
#pgkyl rt-*m-gem_ion_1.bp pl -x x -y y -a --figsize 12,3 --saveas 'ions.png'
#python $repoDir/plotFV.py
