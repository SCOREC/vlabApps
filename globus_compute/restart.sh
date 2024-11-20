#!/bin/bash
#SBATCH --job-name=GlobusRestart
#SBATCH --account=phy220105
#SBATCH --nodes=1
#SBATCH --time=00:10:00
#SBATCH --output=last-globus-restart.log
#SBATCH --begin=21:00



ssh login00 << EOF
hostname
TZ=America/New_York date
cd $HOME
source globus_compute/globus-authenticate.sh
globus-compute-endpoint restart && globus-compute-endpoint list
EOF




sbatch restart.sh

