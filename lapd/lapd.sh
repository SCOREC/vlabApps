#!/bin/bash

gkyl=/anvil/projects/x-phy220105/cws/gkyllPreG0Dev/gkeyllSoftCpu/bin/gkyl

usage="<tEnd> <cells_r> <cells_z> <nFrames> <profile>"
args=5
[[ $# -ne $args ]] && echo "$0 $usage" && exit 1

#there should be a better way...
repoDir=/anvil/projects/x-phy220105/cwsmith/vlabApps/lapd
cd $repoDir 
#gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=LAPD3D5Mg2.lua
original_luaScript=$repoDir/LAPD3D5Mg2_orig.lua
[[ ! -e "$original_luaScript" ]] && echo "luaScript $original_luaScript does not exist" && exit 1

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
sed -i "s!High_vA_profile.txt!${repoDir}/${profile}!" $luaScript

diff $luaScript $original_luaScript #DEBUG

srun -n ${SLURM_NPROCS} $gkyl $luaScript

eval "$(/anvil/projects/x-phy220105/cwsmith/miniforge3/bin/conda shell.bash hook)"
conda activate /anvil/projects/x-phy220105/cwsmith/gkeyllDev/pgkyl
pgkyl LAPD3D5Mg2_fieldEnergy.bp select -c0 plot --logy -x 'time' -y '$|E_x|^2$' \
  --saveas LAPD3D5Mg2_fieldEnergy.png
pgkyl "LAPD3D5Mg2_field_[0-9]*.bp" select --comp 4 --z0 0. --z1 0. collect plot \
 --diverging -x '$t(\mu s)$' -y '$z(m)$' --clabel '$B_y(x=y=0)(T)$' --xscale 1.e6 \
 --saveas LAPD3D5Mg2_field_x0y0_z2pts.png
pgkyl "LAPD3D5Mg2_field_[0-9]*.bp" -t f4 "LAPD3D5Mg2_field_[0-9]*.bp" -t f5 \
 activ -t f4 select --comp 4 --z0 0. --z1 0. --z2 2. collect -l '$z=2m$' -t f4p \
 activ -t f5 select --comp 4 --z0 0. --z1 0. --z2 3.5 collect -l '$z=3.5m$' -t f5p \
 activ -t f4p,f5p plot -f0 -x '$t(\mu s)$' -y '$B_y(x=y=0)(T)$' --xscale 1.e6 \
 --saveas LAPD3D5Mg2_field_x0y0_zTime.png
