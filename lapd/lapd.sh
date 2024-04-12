#!/bin/bash

set -x
echo $GKYL
echo $PGKYL_CONDA_ENV
echo $CONDA
set +x
[[ ! -e "$GKYL" ]] && echo "path to gkyl executable $GKYL does not exist" && exit 1
[[ ! -d "$PGKYL_CONDA_ENV" ]] && echo "path to pgkyl conda environment $PGKYL_CONDA_ENV does not exist or is not a directory" && exit 1
[[ ! -e "$CONDA" ]] && echo "path to conda binary $CONDA does not exist" && exit 1

usage="<gridResolution> <tEnd> <nFrames> <profile>"
args=4
[[ $# -ne $args ]] && echo "$0 $usage" && exit 1

repoDir=$(dirname $(readlink -f $0))
cd $repoDir 
#gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=LAPD3D5Mg2.lua
original_luaScript=$repoDir/LAPD3D5Mg2_orig.lua
[[ ! -e "$original_luaScript" ]] && echo "luaScript $original_luaScript does not exist" && exit 1

#copy the script to the working directory
cp $original_luaScript $luaScript


gridResolution=$1
[[ "$gridResolution" != "16x150" && "$gridResolution" != "32x300" ]] && \
  echo "grid resolution was set to \"$gridResolution\", valid options are [16x150|32x300]" && \
  exit 1
[[ "$gridResolution" == "16x150" ]] && nr=16 && nz=150
[[ "$gridResolution" == "32x300" ]] && nr=32 && nz=300
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

set -x
diff $luaScript $original_luaScript
set +x

## run gkyl
srun -n ${SLURM_NPROCS} $GKYL $luaScript

## post processing
eval "$(${CONDA} shell.bash hook)"
conda activate $PGKYL_CONDA_ENV

pgkyl "LAPD3D5Mg2_field_[0-9]*.bp" select --comp 4 --z0 0. --z1 0. --z2 0.2:18. \
  collect plot --diverging -x '$t(\mu s)$' -y '$z(m)$' --clabel '$B_y(x=y=0)(T)$' \
  --xscale 1.e6 --saveas LAPD3D5Mg2_field_x0y0_zTime.png

pgkyl "LAPD3D5Mg2_field_[0-9]*.bp" -t f4 "LAPD3D5Mg2_field_[0-9]*.bp" -t f5 \
 activ -t f4 select --comp 4 --z0 0. --z1 0. --z2 2. collect -l '$z=2m$' -t f4p \
 activ -t f5 select --comp 4 --z0 0. --z1 0. --z2 3.5 collect -l '$z=3.5m$' -t f5p \
 activ -t f4p,f5p plot -f0 -x '$t(\mu s)$' -y '$B_y(x=y=0)(T)$' --xscale 1.e6 \
 --saveas LAPD3D5Mg2_field_x0y0_z2pts.png
