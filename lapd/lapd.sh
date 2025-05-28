#!/bin/bash

set -x
echo $GKYL
echo $PGKYL_ENV
set +x
[[ ! -e "$GKYL" ]] && echo "path to gkyl executable $GKYL does not exist" && exit 1
[[ ! -e "$PGKYL_ENV" ]] && echo "path to pgkyl python environment $PGKYL_ENV does not exist" && exit 1

usage="<gridResolution> <tEnd> <nFrames> <profile> <J0> <driveFreq> <antRamp> <tAntOff> <lAnt> <elcTemp> <Te_Ti> <n0>"
numArgs=12
[[ $# -ne $numArgs ]] && echo "$0 $usage" && exit 1

repoDir=$(dirname $(readlink -f $0))
cd $repoDir 
#gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=LAPD3D5Mg0.lua
original_luaScript=$repoDir/LAPD3D5Mg0_orig.lua
[[ ! -e "$original_luaScript" ]] && echo "luaScript $original_luaScript does not exist" && exit 1

#copy the script to the working directory
cp $original_luaScript $luaScript


gridResolution=$1
[[ "$gridResolution" != "16x150" && "$gridResolution" != "32x300" && "$gridResolution" != "64x700" ]] && \
  echo "grid resolution was set to \"$gridResolution\", valid options are [16x150|32x300|64x700]" && \
  exit 1
[[ "$gridResolution" == "16x150" ]] && nr=16 && nz=150
[[ "$gridResolution" == "32x300" ]] && nr=32 && nz=300
[[ "$gridResolution" == "64x700" ]] && nr=64 && nz=700
sed -i "s/nr = 64/nr = ${nr}/" $luaScript
sed -i "s/nz = 700/nz = ${nz}/" $luaScript

tEnd=$2
sed -i "s/tEnd = 150.0\\/omegaCi/tEnd = ${tEnd}\\/omegaCi/" $luaScript

nFrames=$3
sed -i "s/nFrames = 150/nFrames = ${nFrames}/" $luaScript

profile=$4
[[ "$profile" != "Flat_vA_profile.txt" && "$profile" != "Low_vA_profile.txt" && "$profile" != "High_vA_profile.txt" ]] && \
  echo "profile was set to \"$profile\", valid options are [Flat|Low|High]_vA_profile.txt" && \
  exit 1
cp ${repoDir}/${profile} .
sed -i "s!High_vA_profile.txt!${profile}!" $luaScript

J0=$5
sed -i "s/J0 = 1.0e4/J0 = ${J0}/" $luaScript

driveFreq=$6
sed -i "s/driveFreq = 4.5e4/driveFreq = ${driveFreq}/" $luaScript

antRamp=$7
sed -i "s!antRamp = 0.25/driveFreq!antRamp = ${antRamp}!" $luaScript

tAntOff=$8
sed -i "s!tAntOff = 1.5/driveFreq - antRamp!tAntOff = ${tAntOff}!" $luaScript

lAnt=$9
sed -i "s!lAnt = 0.28!lAnt = ${lAnt}!" $luaScript

elcTemp=${10}
sed -i "s!elcTemp = 7.*eV!elcTemp = ${elcTemp}*eV!" $luaScript

Te_Ti=${11}
sed -i "s!Te_Ti = 5.0!Te_Ti = ${Te_Ti}!" $luaScript

n0=${12}
sed -i "s!n0 = 7.0e18!n0 = ${n0}!" $luaScript

set -x
diff $luaScript $original_luaScript
set +x

## run gkyl
module load gcc/11.2.0
module load cmake/3.20.0
module load libffi
export PATH=$PATH:/anvil/projects/x-phy220105/gkylMarch2025/Python-3.13.2/install/bin/
srun -n ${SLURM_NPROCS} $GKYL $luaScript

## post processing
source $PGKYL_ENV

pgkyl "LAPD3D5Mg0-field_[0-9]*.gkyl" select --comp 4 --z0 0. --z1 0. \
  collect plot --diverging -x '$t(\mu s)$' -y '$z(m)$' --clabel '$B_y(x=y=0)(T)$' \
  --xscale 1.e6 --saveas LAPD3D5Mg0_field_x0y0_zTime.png

pgkyl "LAPD3D5Mg0-field_[0-9]*.gkyl" -t f4 "LAPD3D5Mg0-field_[0-9]*.gkyl" -t f5 \
 activ -t f4 select --comp 4 --z0 0. --z1 0. --z2 2. collect -l '$z=2m$' -t f4p \
 activ -t f5 select --comp 4 --z0 0. --z1 0. --z2 3.5 collect -l '$z=3.5m$' -t f5p \
 activ -t f4p,f5p plot -f0 -x '$t(\mu s)$' -y '$B_y(x=y=0)(T)$' --xscale 1.e6 \
 --saveas LAPD3D5Mg0_field_x0y0_z2pts.png
