#!/bin/bash

function getMachineName() {
  hostname=`hostname`
  if [[ $hostname == *gkeyll-vc-test00* ]]; then
    echo "js2"
  elif [[ $hostname == *anvil* ]]; then
    echo "anvil"
  else
    exit 1
  fi
}

set -x
echo $GKYL
echo $PGKYL_ENV
set +x
[[ ! -e "$GKYL" ]] && echo "path to gkyl executable (GKYL) \"$GKYL\" does not exist" && exit 1
[[ ! -e "$PGKYL_ENV" ]] && echo "path to pgkyl python environment (PGKYL_ENV) \"$PGKYL_ENV\" does not exist" && exit 1

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

#copy the script to the working directory
cp $original_luaScript $luaScript

#mass_elc = 1.0 / 25.0
electronMass=$2
sed -i "s/mass_elc = 1.0 \\/ 25.0/mass_elc = 1.0 \\/ ${electronMass}/" $luaScript

#Lx = 25.6 * di0
Lx=$3
sed -i "s/Lx = 25.6/Lx = ${Lx}/" $luaScript
#Ly = 12.8 * di0
Ly=$4
sed -i "s/Ly = 12.8/Ly = ${Ly}/" $luaScript

#tEnd = 25.0/OmegaCi0
tEnd=$5
sed -i "s/tEnd = 250.0/tEnd = ${tEnd}/" $luaScript

#Nx = 128
Nx=$6
sed -i "s/Nx = 128/Nx = ${Nx}/" $luaScript

#Ny = 64
Ny=$7
sed -i "s/Ny = 64/Ny = ${Ny}/" $luaScript

diff $luaScript $original_luaScript #DEBUG

## run gkyl
machine=$(getMachineName)
if [[ $machine == "anvil" ]]; then
  echo "machine: anvil"
  module load gcc/11.2.0
  module load cmake/3.20.0
  module load libffi
  export PATH=$PATH:/anvil/projects/x-phy220105/gkylMarch2025/Python-3.13.2/install/bin/
  srun -n ${SLURM_NPROCS} $GKYL $luaScript
elif [[ $machine == "js2" ]]; then
  echo "machine: jetstream2"
  hosts=hostfile.${SLURM_JOBID}
  srun hostname > $hosts
  mpirun --mca io ^ompio --mca btl_tcp_if_include eth0 -n ${SLURM_NPROCS} -hostfile $hosts $GKYL $luaScript
fi

## post processing
if [[ $machine == "anvil" ]]; then
  echo "machine: anvil"
  source $PGKYL_ENV
  pgkyl rt-*m-gem_field_1.bp sel -c 0,1,2,3,4,5 pl -x x -y y --diverging -a --figsize 12,3 --saveas 'fields.png'
  pgkyl rt-*m-gem_elc_1.bp pl -x x -y y -a --figsize 12,3 --saveas 'electrons.png'
  pgkyl rt-*m-gem_ion_1.bp pl -x x -y y -a --figsize 12,3 --saveas 'ions.png'
  python $repoDir/plotFV.py
elif [[ $machine == "js2" ]]; then
  echo "machine: jetstream2 - ERROR python3.12 install is missing on the compute nodes"
fi
