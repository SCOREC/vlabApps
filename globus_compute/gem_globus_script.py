from globus_compute_sdk import Client, Executor
import os


# Exit Status key:
# 0 - Successful execution
# 1 - Job submitted, but unsuccessful
# 2 - Timeout, stuck in queue for too long
def run_gem_reconnection():
    import subprocess
    import time

    # Run slurm script
    result = subprocess.run([
        "sbatch", "/home/x-ceich1/slurm_jobs/gem_job.sh", "/home/x-ceich1", "/anvil/projects/x-phy220105/cws/gkyllPreG0Dev/gkeyllSoftCpu/bin/gkyl", "/anvil/projects/x-phy220105/cwsmith/gkeyllDev/pgkyl", "/anvil/projects/x-phy220105/cwsmith/miniforge3/bin/conda"        
    ], capture_output=True, text=True)

    # Wait for job to finish
    stdout = result.stdout
    job_id = None
    if "Submitted batch job" in stdout:
        job_id = stdout.split()[-1].strip()

    if job_id:
        start_time = time.time()
        timeout = 30 * 60
        while True:
            if time.time() - start_time > timeout:
                print(f"Timeout reached after {timeout / 60} minutes. Quitting job.")
                return "", "", 2
                break
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

    if "Main loop completed" in job_output:
        return job_output, job_error, 0
    else:
        return job_output, job_error, 1

# Submit to Globus
print("Starting script")
client = Client()
anvil_endpoint_id = os.environ.get('ANVIL_ENDPOINT_ID')
with Executor(endpoint_id=anvil_endpoint_id) as ex:
    print("Submitting function")
    future = ex.submit(run_gem_reconnection)

    out, err, status = future.result()
    with open("gem_job.out", "w") as out_file:
        out_file.write(out)

    with open("gem_job.err", "w") as err_file:
        err_file.write(err)

print(f"Job finished with exit status {status}")
