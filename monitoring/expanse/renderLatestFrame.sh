#!/bin/bash

module purge
eval $(/home/gcommunityuser/cwsmith/miniconda3/bin/conda shell.bash hook)

#returns 0 if done, 1 otherwise
function isGkylDone() {
  grep -q 'Main loop completed' *.log
  return $?
}

function runPgkyl() {
  local file=$1
  pgkyl=/home/gcommunityuser/cwsmith/miniconda3/bin/pgkyl
  $pgkyl $file select -c0 plot --logy -x 'time' -y '\$|E_x|^2\$' --save
}

loopCount=0
while true ; do
  sleep 1
  echo $loopCount
  loopCount=$((loopCount+1))
  file=ex_fieldEnergy.bp
  [ -f "$file" ] && runPgkyl $file
  isGkylDone && echo "Gkyl done" && break
done
