from globus_compute_sdk import Client, Executor
import os
from enum import Enum


# Enum for error codes
class JobStatus(Enum):
    COMPLETED_SUCCESSFUL = 0
    COMPLETED_UNSUCCESSFUL = 1
    SLURM_ERROR = 2
    TIMEOUT = 3
    GLOBUS_ERROR = 4

# Print result of error code
def check_status(status):
    if status == JobStatus.COMPLETED_SUCCESSFUL:
        print("Job completed successfully.")
    elif status == JobStatus.COMPLETED_UNSUCCESSFUL:
        print("Job was submitted but did not complete successfully.")
    elif status == JobStatus.SLURM_ERROR:
        print("Slurm error encountered while submitting the job.")
    elif status == JobStatus.TIMEOUT:
        print("Job timed out during execution.")
    elif status == JobStatus.GLOBUS_ERROR:
        print("Globus error occurred.")


def run_gem_reconnection(out_path, err_path, slurm_path, home_dir, gkyl_path, pgkyl_conda_path, conda_path):
    import subprocess
    import time

    # Slurm arguments
    slurm_options = {
        "--time": "00:05:00",
        "--account": "phy220105",
        "--job-name": "gem_reconnection",
        "--nodes": "1",
        "--ntasks": "1",
        "--output": out_path,
        "--error": err_path
    }
    slurm_args = [f"{key}={value}" for key, value in slurm_options.items()]

    # Command-line arguments for the script
    script_args = [
        slurm_path,
        home_dir,
        gkyl_path,
        pgkyl_conda_path,
        conda_path
    ]

    # Run the command
    command = ["sbatch"] + slurm_args + script_args
    result = subprocess.run(command, capture_output=True, text=True)

    # Wait for job to finish
    stdout = result.stdout
    job_id = None
    if "Submitted batch job" in stdout:
        job_id = stdout.split()[-1].strip()
    else:
        return result.stdout, result.stderr, 2

    if job_id:
        start_time = time.time()
        timeout = 30 * 60
        while True:
            if time.time() - start_time > timeout:
                print(f"Timeout reached after {timeout / 60} minutes. Quitting job.")
                return "", "", 3
                break
            squeue_result = subprocess.run(
                ["squeue", "-j", job_id],
                capture_output=True, text=True
            )
            if job_id not in squeue_result.stdout:
                break
            time.sleep(60)

    with open(out_path, "r") as out_file:
        job_output = out_file.read()
    with open(err_path, "r") as err_file:
        job_error = err_file.read()

    if "Main loop completed" in job_output:
        return job_output, job_error, 0
    else:
        return job_output, job_error, 1


# Reset output files
if os.path.isfile("gem_job.out"):
        os.remove("gem_job.out")
if os.path.isfile("gem_job.err"):
        os.remove("gem_job.err")

# Translate error code to enum
status_map = {
    0: JobStatus.COMPLETED_SUCCESSFUL,
    1: JobStatus.COMPLETED_UNSUCCESSFUL,
    2: JobStatus.SLURM_ERROR,
    3: JobStatus.TIMEOUT,
    4: JobStatus.GLOBUS_ERROR
}

# Submit to Globus
print("Starting script")
try:
    client = Client()
    
    anvil_endpoint_id = os.environ.get('ANVIL_ENDPOINT_ID')
    if not anvil_endpoint_id:
        raise ValueError("Environment variable 'ANVIL_ENDPOINT_ID' is not set.")
    
    with Executor(endpoint_id=anvil_endpoint_id) as ex:
        print("Submitting function")
        
        future = ex.submit(
            run_gem_reconnection, 
            out_path="/home/x-ceich1/slurm_jobs/gem.out", 
            err_path="/home/x-ceich1/slurm_jobs/gem.err", 
            slurm_path="/home/x-ceich1/slurm_jobs/gem_slurm.sh", 
            home_dir="/home/x-ceich1", 
            gkyl_path="/anvil/projects/x-phy220105/cws/gkyllPreG0Dev/gkeyllSoftCpu/bin/gkyl", 
            pgkyl_conda_path="/anvil/projects/x-phy220105/cwsmith/gkeyllDev/pgkyl", 
            conda_path="/anvil/projects/x-phy220105/cwsmith/miniforge3/bin/conda"
        )

        out, err, status_code = future.result()
        status = status_map[status_code]
        with open("gem_job.out", "w") as out_file:
            out_file.write(out)

        with open("gem_job.err", "w") as err_file:
            err_file.write(err)
except Exception as e:
    print("Error occured while submitting to Globus")
    with open("gem_job.err", "w") as err_file:
        err_file.write(f"Error: {e}")
    status = JobStatus.GLOBUS_ERROR

# Print results
check_status(status)
