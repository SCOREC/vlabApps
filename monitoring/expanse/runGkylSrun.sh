#!/bin/bash
module load cpu
module load gcc/10.2.0/npcyll4
module load openmpi/4.1.3/oq3qvsv
module load python/3.8.12/7zdjza7
cd $SLURM_SUBMIT_DIR
echo $PWD
gkyl=/home/gcommunityuser/cwsmith/gkeyllDev/gkeyllSoft/bin/gkyl
render=/home/gcommunityuser/cwsmith/gkeyllDev/renderLatestFrame.sh
set -x
srun --exclusive -n 1 $gkyl $1 &
srun --exclusive -n 1 $render &
wait
set +x
