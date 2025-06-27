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

usage="<gridResolution> <tEnd> <nFrames> <profile> <J01> <driveFreq1> <antRamp1> <tAntOn1> <tAntOff1> <lAnt1> <antZ1> <antOrientation1> <J02> <driveFreq2> <antRamp2> <tAntOn2> <tAntOff2> <lAnt2> <antZ2> <antOrientation2> <B0> <elcTemp> <Te_Ti> <n0>"
numArgs=24
[[ $# -ne $numArgs ]] && echo "$0 $usage" && exit 1

repoDir=$(dirname $(readlink -f $0))
cd $repoDir 
gitHash=$(git rev-parse HEAD)
echo "git hash: $gitHash"
cd -

luaScript=LAPD.lua
original_luaScript=$repoDir/LAPD.lua
[[ ! -e "$original_luaScript" ]] && echo "luaScript $original_luaScript does not exist" && exit 1

#copy the script to the working directory
cp $original_luaScript $luaScript
[[ ! -s "$luaScript" ]] && echo "lua script $luaScript is empty" && exit 1

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
[[ "$profile" != "Flat_vA_profile.txt" && "$profile" != "Low_vA_profile.txt" && "$profile" != "High_vA_profile.txt" \
       && "$profile" != "None" ]] && \
  echo "profile was set to \"$profile\", valid options are None or [Flat|Low|High]_vA_profile.txt" && \
  exit 1
if [${profile} = "None"]; then
    sed -i "s!readBProfile = true!readBProfile = false!" $luaScript
else
    cp ${repoDir}/${profile} .
    sed -i "s!High_vA_profile.txt!${profile}!" $luaScript
fi

J01=$5
sed -i "s/J01 = 1.0e4/J01 = ${J01}/" $luaScript

driveFreq1=$6
sed -i "s/driveFreq1 = 7.64e4/driveFreq1 = ${driveFreq1}/" $luaScript

antRamp1=$7
sed -i "s!antRamp1 = 0.25/driveFreq1!antRamp1 = ${antRamp1}!" $luaScript

tAntOn1=$8
sed -i "s!tAntOn1 = 0.!tAntOn1 = ${tAntOn1}!" $luaScript

tAntOff1=$9
sed -i "s!tAntOff1 = 1.5/driveFreq1 - antRamp1!tAntOff1 = ${tAntOff1}!" $luaScript

lAnt1=$10
sed -i "s!lAnt1 = 0.2178!lAnt1 = ${lAnt1}!" $luaScript

antZ1=$11
sed -i "s!antZ1 = 0.!antZ1 = ${antZ1}!" $luaScript

antOrientation1=$12
sed -i 's!antOrientation1 = "x"!antOrientation1 = "'"${antOrientation1}"'"!' $luaScript

J02=$13
sed -i "s/J02 = 0./J02 = ${J02}/" $luaScript

driveFreq2=$14
sed -i "s/driveFreq2 = 7.64e4/driveFreq2 = ${driveFreq2}/" $luaScript

antRamp2=$15
sed -i "s!antRamp2 = 0.25/driveFreq2!antRamp2 = ${antRamp2}!" $luaScript

tAntOn2=$16
sed -i "s!tAntOn2 = 0.!tAntOn2 = ${tAntOn2}!" $luaScript

tAntOff2=$17
sed -i "s!tAntOff2 = 1.5/driveFreq2 - antRamp2!tAntOff2 = ${tAntOff2}!" $luaScript

lAnt2=$18
sed -i "s!lAnt2 = 0.2178!lAnt2 = ${lAnt2}!" $luaScript

antZ2=$19
sed -i "s!antZ2 = 10.!antZ2 = ${antZ2}!" $luaScript

antOrientation2=$20
sed -i 's!antOrientation2 = "y"!antOrientation2 = "'"${antOrientation2}"'"!' $luaScript

B0=${21}
sed -i "s!B0 = 0.08!B0 = ${B0}!" $luaScript

elcTemp=${22}
sed -i "s!elcTemp = 7.*eV!elcTemp = ${elcTemp}*eV!" $luaScript

Te_Ti=${23}
sed -i "s!Te_Ti = 5.0!Te_Ti = ${Te_Ti}!" $luaScript

n0=${24}
sed -i "s!n0 = 7.0e18!n0 = ${n0}!" $luaScript

set -x
diff $luaScript $original_luaScript
set +x

## run gkyl
[[ ${SLURM_NPROCS} < 96 ]] && echo "SLURM_NPROCS \'$SLURM_NPROCS\' must be at least 96" && exit 1
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
source $PGKYL_ENV

pgkyl LAPD-ext_em_0.gkyl sel--comp 5 --z0 0. --z1 0. plot -f0 -x '$z(m)$' -y '$B_z(x=y=0)(T)$' \
 --saveas LAPD_Bz_x0y0_background.png

"LAPD-field_[0-9]*.gkyl" select --comp 3 --z0 0. --z1 0. \
  collect plot --diverging -x '$t(\mu s)$' -y '$z(m)$' --clabel '$B_x(x=y=0)(T)$' \
  --xscale 1.e6 --saveas LAPD_Bx_x0y0_zTime.png

pgkyl "LAPD-field_[0-9]*.gkyl" select --comp 3 --z0 0. --z1 0. \
  collect plot --diverging -x '$t(\mu s)$' -y '$z(m)$' --clabel '$B_x(x=y=0)(T)$' \
  --xscale 1.e6 --saveas LAPD_Bx_x0y0_zTime.png

pgkyl "LAPD-field_[0-9]*.gkyl" select --comp 4 --z0 0. --z1 0. \
  collect plot --diverging -x '$t(\mu s)$' -y '$z(m)$' --clabel '$B_y(x=y=0)(T)$' \
  --xscale 1.e6 --saveas LAPD_By_x0y0_zTime.png

pgkyl "LAPD-field_[0-9]*.gkyl" -t f4 "LAPD-field_[0-9]*.gkyl" -t f5 \
 activ -t f4 select --comp 3 --z0 0. --z1 0. --z2 2. collect -l '$z=2m$' -t f4p \
 activ -t f5 select --comp 3 --z0 0. --z1 0. --z2 3.5 collect -l '$z=3.5m$' -t f5p \
 activ -t f4p,f5p plot -f0 -x '$t(\mu s)$' -y '$B_x(x=y=0)(T)$' --xscale 1.e6 \
 --saveas LAPD_Bx_x0y0_z2pts.png

pgkyl "LAPD-field_[0-9]*.gkyl" -t f4 "LAPD-field_[0-9]*.gkyl" -t f5 \
 activ -t f4 select --comp 4 --z0 0. --z1 0. --z2 2. collect -l '$z=2m$' -t f4p \
 activ -t f5 select --comp 4 --z0 0. --z1 0. --z2 3.5 collect -l '$z=3.5m$' -t f5p \
 activ -t f4p,f5p plot -f0 -x '$t(\mu s)$' -y '$B_y(x=y=0)(T)$' --xscale 1.e6 \
 --saveas LAPD_By_x0y0_z2pts.png
