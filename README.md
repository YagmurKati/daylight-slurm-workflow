# Daylight-Controlled SLURM Workflow (Nextflow)

This repository provides two Nextflow-based workflows designed for the SLURM cluster at **HPC@HU (Humboldt University, Berlin)**. They support preferential scheduling of **energy-intensive jobs during daylight hours** using either fixed time windows or dynamically retrieved sunrise/sunset times for Berlin.

The workflows are **portable** and can be adapted to other SLURM-based HPC systems by:

- Editing **latitude/longitude** in `slurm_daylight_automated_scheduler.sh`
- Updating **partition settings** in `nextflow.config`

---

## Prerequisites

- An account on HU Berlin's HPC system
- Access to the `slurm-login` node
- Nextflow installed on the cluster (`module load nextflow`)
- A Linux/HPC shell environment with GNU `date` support (`date -d`)
- If using the automated scheduler: `jq` binary available in your home directory (`$HOME/jq`)

---

## Quick Start

### Option 1: Fixed Daylight Window (07:00–19:00)

This option uses a static daylight window. The window can be adjusted in `slurm_daylight_scheduler.sh`.

```bash
ssh your_username@slurm-login.hpc-service.hu-berlin.de
module load nextflow
chmod +x slurm_daylight_scheduler.sh
nextflow run daylight_controlled_workflow.nf -resume
```

---

### Option 2: Dynamic Daylight Times (Berlin)

This option retrieves sunrise and sunset times for Berlin from an online API.

```bash
ssh your_username@slurm-login.hpc-service.hu-berlin.de
module load nextflow
chmod +x slurm_daylight_automated_scheduler.sh
nextflow run daylight_automated_workflow.nf -resume
```
This requires a working copy of `jq` in your home directory as `$HOME/jq`.

---

## Daylight-Aware Scheduling

This workflow supports two options for energy-aware job scheduling:

### Option 1: Fixed Daylight Window (`slurm_daylight_scheduler.sh`)

This script assumes a fixed daylight window between 07:00 and 19:00.

- It checks the current time.
- If the current time is outside the daylight window, it sets a SLURM directive, `--begin=...`, to delay the job until 07:00 the next morning.
- If the job cannot run during daylight (e.g., due to cluster load), it will start as soon as resources become available afterward.

This option allows users to adjust the daylight window manually in the script.

### Option 2: Dynamic Sunlight Detection (`slurm_daylight_automated_scheduler.sh`)

This script automatically retrieves the actual sunrise and sunset times for Berlin using the sunrise-sunset.org API.

- It fetches real daylight times based on the current date and location (Berlin: lat=52.52, lng=13.41).
- It adjusts for practical energy use by setting jobs to start 1 hour after sunrise and before 1 hour prior to sunset.
- If the current time is outside this refined daylight window, the script delays the job to the next sunrise period.
- If the job cannot run during daylight (e.g., because all nodes are busy), it will still run afterward when resources are available.

Use `daylight_controlled_workflow.nf` with Option 1 (fixed daylight) and `daylight_automated_workflow.nf` with Option 2 (dynamic daylight detection).

---

## Workflow Overview

This workflow consists of several processes, each assigned to a specific SLURM partition depending on its resource requirements.

| Process Name            | Description                                   | Partition Used  | Notes                                   |
|--------------------------|-----------------------------------------------|-----------------|-----------------------------------------|
| `standard_task`          | Standard task with low resource usage         | `standard`      | Always runs immediately                 |
| `longrun_task`           | Task with extended wall time                  | `longrun`       | Useful for long simulations             |
| `highenergy_std_task`    | CPU-intensive job, prefers daylight           | `standard`      | Daylight-aware via `--begin`             |
| `highenergy_memory_task` | Memory-heavy job, prefers daylight (optional) | `large_memory`  | Disabled by default (optional)          |
| `gpu_task`               | GPU job, prefers daylight (optional)          | `gpu`           | Disabled by default (optional)          |

### Notes

- Tasks marked as **optional** are initially **commented out** and must be manually enabled.
- Daylight-aware processes will attempt to start between 07:00–19:00 but will still run later if needed.

To enable optional tasks, edit `daylight_controlled_workflow.nf` or `daylight_automated_workflow.nf` and uncomment:

```groovy
// highenergy_memory_task(cluster_options_ch)
// gpu_task(cluster_options_ch)
```

---

## Customize the Processes

The example processes in this workflow use `sleep 30` as a placeholder.
Replace these with your actual computational tasks or scripts.

For example, in `daylight_controlled_workflow.nf`, change:

```groovy
"""
sleep 30
"""
```

to something like:

```groovy
"""
python run_simulation.py --input params.txt
"""
```

This allows the workflow to be adapted to a real workload while keeping the daylight scheduling logic.

---

## Output and Work Directory

- All intermediate files and process execution data are stored in the `work/` directory.
- Each job’s SLURM submission script, stdout, stderr, and input/output files are located under a unique hash-named subfolder.

To inspect job details:

```bash
cd work/<unique_hash>/
```

To monitor SLURM jobs:

```bash
squeue
sacct -S today -u your_username
```

---

## Repository Layout

```text
.
├── daylight_controlled_workflow.nf           # Main workflow using fixed daylight hours (07:00–19:00)
├── daylight_automated_workflow.nf            # Main workflow using real-time sunrise/sunset from API
├── nextflow.config                           # SLURM resource and label definitions
├── slurm_daylight_scheduler.sh               # Fixed daylight scheduler (default 07:00–19:00)
├── slurm_daylight_automated_scheduler.sh     # Automated daylight scheduler (Berlin-based sunrise/sunset)
├── README.md                                 # You are here
├── work/                                     # Working directory (auto-generated by Nextflow)
└── .nextflow/                                # Nextflow cache and runtime metadata
```

---

## Getting jq Locally

If jq is not available on your system (as is the case on HPC@HU), download it manually:

```bash
wget -O $HOME/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x $HOME/jq
```

Make sure it is executable and referenced as `$HOME/jq` in the script. It does not need to be added to `$PATH`.

---

## Cleanup

To clean up all intermediate files:

```bash
rm -rf work/ .nextflow/ .nextflow.log
```

---

## Debugging

For additional diagnostics:

```bash
nextflow run daylight_controlled_workflow.nf -resume -with-trace -with-report
```

---

## Why Daylight Scheduling?

Running energy-intensive computing tasks during daylight hours (07:00–19:00) can reduce the carbon footprint of high-performance computing when the electricity mix contains a higher share of solar generation. In Germany, this effect is particularly relevant in spring and summer.

In June and July, solar energy production in Germany reaches its yearly peak, according to data from the International Energy Agency (IEA) [1]. Germany generated a record 9 terawatt-hours (TWh) of solar electricity in June 2023, the highest monthly solar output recorded in the country at that time [2].

Carbon-aware scheduling has also been shown to reduce emissions in practice. A scheduling system called S.C.A.L.E., developed at ING and TU Delft, delayed computing jobs to periods of lower grid carbon intensity. This approach reduced the carbon emissions of data pipelines by about 20% [3].

### References

[1] IEA, “Monthly generation of solar PV in Germany,” International Energy Agency, 2023. Available: https://www.iea.org/data-and-statistics/charts/monthly-generation-of-solar-pv-in-germany  
[2] Fraunhofer ISE, “Public Net Electricity Generation in Germany 2023,” Fraunhofer Institute for Solar Energy Systems, 2024. Available: https://www.ise.fraunhofer.de/en/press-media/press-releases/2024/public-electricity-generation-2023-renewable-energies-cover-the-majority-of-german-electricity-consumption-for-the-first-time.html  
[3] Den Toonder, J., Braakman, P., & Durieux, T. (2024). S.C.A.L.E: A CO2-Aware Scheduler for OpenShift at ING. FSE Companion - Companion Proceedings of the 32nd ACM International
Conference on the Foundations of Software Engineering (pp. 429-439). ACM. https://doi.org/10.1145/3663529.3663862

---

## Contact

For questions or suggestions, contact yagmur.kati@hu-berlin.de.
