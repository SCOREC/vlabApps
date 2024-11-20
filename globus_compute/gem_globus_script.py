from globus_compute_sdk import Client, Executor
import os

def run_gem_reconnection():
    import subprocess
    import time

    # Run slurm script
    result = subprocess.run([
        "sbatch", "/home/x-ceich1/slurm_jobs/gem_job.sh", "/home/x-ceich1", "/anvil/projects/x-phy220105/cws/gkyllPreG0Dev/gkeyllSoftCpu/bin/gkyl", "/anvil/projects/x-phy220105/cwsmith/gkeyllDev/pgkyl", "/anvil/projects/x-phy220105/cwsmith/miniforge3/bin/conda"
    ], capture_output=True, text=True)

    # Wait for job to finish
    time.sleep(30)
    stdout = result.stdout
    job_id = None
    if "Submitted batch job" in stdout:
        job_id = stdout.split()[-1].strip()

    if job_id:
        while True:
            squeue_result = subprocess.run(
                ["squeue", "-j", job_id],
                capture_output=True, text=True
            )
            if job_id not in squeue_result.stdout:
                break
            time.sleep(60)
    
    output_file = "/home/x-ceich1/slurm_jobs/gem.out"
    error_file = "/home/x-ceich1/slurm_jobs/gem.err"

    with open(output_file, "r") as out_file:
        job_output = out_file.read()
    with open(error_file, "r") as err_file:
        job_error = err_file.read()

    return job_output, job_error

# Submit to Globus
print("Starting script")
client = Client()
anvil_endpoint_id = os.environ.get('ANVIL_ENDPOINT_ID')
with Executor(endpoint_id=anvil_endpoint_id) as ex:
    print("Submitting function")
    future = ex.submit(run_gem_reconnection)

    out, err = future.result()
    with open("gem_job.out", "w") as out_file:
        out_file.write(out)

    with open("gem_job.err", "w") as err_file:
        err_file.write(err)

print("Output and error files have been saved")
