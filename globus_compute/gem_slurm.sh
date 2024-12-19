#!/bin/bash

if [ "$#" -ne 4 ]; then
	echo "Error: Usage is sbatch gem_job.sh <home_directory> <GKYL> <PGKYL_CONDA_ENV> <CONDA>."
	exit 1
fi

homeDir="$1"

export GKYL="$2"
export PGKYL_CONDA_ENV="$3"
export CONDA="$4"
export VLAB_REPODIR=$homeDir/vlabApps

# Change working directory so all generated files end up in the right place
cd $homeDir/slurm_jobs/gem_job_files

# Run the Gem Reconnection
bash ${VLAB_REPODIR}/gemReconnection/gemReconnection.sh 5 25 25.6 12.8 25 64 32
