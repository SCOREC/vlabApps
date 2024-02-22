#!/bin/bash

usage="<tEnd> <cells_r> <cells_z> <nFrames> <profile>"
args=5
[[ $# -ne $args ]] && echo "$0 $usage" && exit 1

#there should be a better way...
repoDir=/export/vlabApps/lapd
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=LAPD3D5Mg2.lua
original_luaScript=$repoDir/$luaScript
[[ ! -e "$original_luaScript" ]] && echo "luaScript $1 does not exist" && exit 1

#copy the script to the working directory
cp $original_luaScript $luaScript

tEnd=$1
sed -i "s/tEnd = 150.0\\/omegaCi/tEnd = ${tEnd}\\/omegaCi/" $luaScript

nr=$2
sed -i "s/nr = 64/nr = ${nr}/" $luaScript
nz=$3
sed -i "s/nr = 700/nr = ${nr}/" $luaScript

nFrames=$4
sed -i "s/nFrames = 150/nFrames = ${nFrames}/" $luaScript

profile=$5
[[ "$profile" != "Flat_vA_profile.txt" && "$profile" != "Low_vA_profile.txt" && "$profile" != "High_vA_profile.txt" ]] && \
  echo "profile was set to \"$profile\", valid options are [Flat|Low|High]_vA_profile.txt" && \
  exit 1
sed -i "s/High_vA_profile.txt/${profile}/" $luaScript

## domain decompositon
set -x
cuts=$(python3 ${repoDir}/getDecomposition.py $nr $nz)
ncr=$(echo $cuts | awk '{print $1}')
ncz=$(echo $cuts | awk '{print $2}')
sed -i "s/ncx = 8/ncx = ${ncr}/" $luaScript
sed -i "s/ncy = 8/ncy = ${ncr}/" $luaScript
sed -i "s/ncz = 24/ncz = ${ncz}/" $luaScript

diff $luaScript $original_luaScript #DEBUG

#eval "$(conda shell.bash hook)"
#conda activate /export/gkeyllSoft/postgkyl
#[[ ! -e $luaScript ]] && echo "Lua script $luaScript does not exist" && exit 1

#hosts=hostfile.${SLURM_JOBID}
#srun hostname > $hosts
#mpirun --mca btl_tcp_if_include eth0 -n ${SLURM_NPROCS} -hostfile $hosts /export/gkeyllSoft/bin/gkyl $luaScript
