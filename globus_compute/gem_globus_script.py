from globus_compute_sdk import Client, Executor
import os


# Exit Status key:
# 0 - Successful execution
# 1 - Job submitted, but unsuccessful
# 2 - Slurm Error while submitting job
# 3 - Timeout
# 4 - Globus Error
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

# Reset output files
if os.path.isfile("gem_job.out"):
        os.remove("gem_job.out")
if os.path.isfile("gem_job.err"):
        os.remove("gem_job.err")

# Submit to Globus
print("Starting script")
try:
    client = Client()
    
    anvil_endpoint_id = os.environ.get('ANVIL_ENDPOINT_ID')
    if not anvil_endpoint_id:
        raise ValueError("Environment variable 'ANVIL_ENDPOINT_ID' is not set.")
    
    with Executor(endpoint_id=anvil_endpoint_id) as ex:
        print("Submitting function")
        future = ex.submit(run_gem_reconnection)

        out, err, status = future.result()
        with open("gem_job.out", "w") as out_file:
            out_file.write(out)

        with open("gem_job.err", "w") as err_file:
            err_file.write(err)
except Exception as e:
    print("Error occured while submitting to Globus")
    with open("gem_job.err", "w") as err_file:
        err_file.write(f"Error: {e}")
    status = 4

# Print results
print(f"Exit code {status}: ", end="")
if status == 0:
    print("Job completed successfully.")
elif status == 1:
    print("Job was submitted but did not complete successfully.")
elif status == 2:
    print("Slurm error encountered while submitting the job.")
elif status == 3:
    print("Job timed out during execution.")
elif status == 4:
    print("Globus error occurred.")
