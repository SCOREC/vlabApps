#!/bin/bash
export GKYL=/export/g0soft/gkeyllSoft/gkylzero/bin/gkyl
export PGKYL_ENV=/export/g0dev/pgkyl/bin/activate

date=$(date +"%Y_%m_%d_%H_%S")
work=gemTest_${date}
mkdir $work
pushd $work

model=5
electron_mass=25
Lx=25.6
Ly=12.8
tEnd=25
cellsX=64
cellsY=32
bin=/export/vlabApps/gemReconnection/gemReconnection.sh
$bin $model $electron_mass $Lx $Ly $tEnd $cellsX $cellsY

