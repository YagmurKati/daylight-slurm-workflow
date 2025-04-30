# Daylight-Controlled SLURM Workflow (Nextflow)

This repository contains a modular and energy-aware HPC workflow written in [Nextflow](https://www.nextflow.io/), designed for execution on the HU Berlin SLURM cluster.

The pipeline schedules high-energy or GPU-heavy jobs **preferentially during daylight hours** (07:00–19:00), while ensuring other jobs execute without delay.

---

## 🔧 Prerequisites

1. An account on HU Berlin's HPC system
2. Access to the `slurm-login` node
3. Nextflow installed on the cluster (`module load nextflow`)

---

## 🚀 Quick Start

Open your terminal and run the following:

```bash
ssh username@slurm-login.hpc-service.hu-berlin.de
module load nextflow
chmod +x slurm_daylight_scheduler.sh
nextflow run daylight_controlled_workflow.nf -resume
```

---

## 📜 Workflow Overview

This workflow consists of several processes, each assigned to a specific SLURM partition depending on its resource requirements.

| Process Name            | Description                                   | Partition Used  | Notes                                   |
|--------------------------|-----------------------------------------------|-----------------|-----------------------------------------|
| `standard_task`          | Standard task with low resource usage         | `standard`      | Always runs immediately                 |
| `longrun_task`           | Task with extended wall time                  | `longrun`       | Useful for long simulations             |
| `highenergy_std_task`    | CPU-intensive job, prefers daylight           | `standard`      | Daylight-aware via `--begin`             |
| `highenergy_memory_task` | Memory-heavy job, prefers daylight (optional) | `large_memory`  | Disabled by default (optional)          |
| `gpu_task`               | GPU job, prefers daylight (optional)          | `gpu`           | Disabled by default (optional)          |

---

### Notes:
- Tasks marked as **optional** are initially **commented out** and must be manually enabled.
- Daylight-aware processes will attempt to start between 07:00–19:00 but will still run later if needed.

---

## ☀️ Daylight-Aware Scheduling

The `slurm_daylight_scheduler.sh` script schedules tasks based on the time of day:

- It checks the current system time.
- If outside daylight hours (07:00–19:00), it adds a SLURM `--begin=...` directive to delay the job until the next daylight window.
- If a job cannot start during daylight (e.g., due to cluster load), it will start as soon as possible afterward.

---

## ⚙️ Enabling GPU or Large Memory Jobs

By default, GPU and large-memory tasks are disabled for faster testing because those partitions are often heavily used.

To enable them:

1. Open the `daylight_controlled_workflow.nf` file.
2. In the `workflow {}` block, locate and uncomment:

```groovy
// highenergy_memory_task(cluster_options_ch)
// gpu_task(cluster_options_ch)
```

After uncommenting, GPU and large-memory jobs will be included and scheduled with daylight-awareness.

---

## 📦 Output and Work Directory

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

## 📁 File Structure

```
.
├── daylight_controlled_workflow.nf      # Main workflow file
├── nextflow.config                      # SLURM resource and label definitions
├── slurm_daylight_scheduler.sh          # Script to delay jobs until daylight
├── README.md                            # You are here
├── work/                                # Working directory (auto-generated)
└── .nextflow/                           # Internal Nextflow state and cache
```

---

## 🧼 Cleanup

To clean up all intermediate files:

```bash
rm -rf work/ .nextflow/ .nextflow.log
```

---

## 🛠️  Debugging

For additional diagnostics:

```bash
nextflow run daylight_controlled_workflow.nf -resume -with-trace -with-report
```

---

## 🌞 Why Daylight Scheduling?

Running energy-intensive computing tasks during daylight hours (07:00–19:00) helps reduce the carbon footprint of high-performance computing. This is because the share of solar energy in Germany's electricity supply is much higher during these hours, especially in spring and summer.

In June and July, solar energy production in Germany reaches its yearly peak, according to data from the International Energy Agency (IEA) [1]. For example, Germany generated a record 9 terawatt-hours (TWh) of solar electricity in June 2023 — the highest monthly solar output ever recorded in the country [2].

Carbon-aware scheduling has also been shown to reduce emissions in practice. A scheduling system called S.C.A.L.E., developed at ING and TU Delft, delayed computing jobs to periods of lower grid carbon intensity. This approach reduced the carbon emissions of data pipelines by about 20% [3].

### 📚 References

[1] IEA, “Monthly generation of solar PV in Germany,” International Energy Agency, 2023. Available: https://www.iea.org/data-and-statistics/charts/monthly-generation-of-solar-pv-in-germany  
[2] Fraunhofer ISE, “Public Net Electricity Generation in Germany 2023,” Fraunhofer Institute for Solar Energy Systems, 2024. Available: https://www.ise.fraunhofer.de/en/press-media/press-releases/2024/public-electricity-generation-2023-renewable-energies-cover-the-majority-of-german-electricity-consumption-for-the-first-time.html  
[3] van der Veen, J., Hoekstra, G., & Lukkien, J., “Carbon-Aware Scheduling for ING’s Data Pipelines,” *Proceedings of the 13th ACM International Conference on Future Energy Systems (e-Energy ’22)*, June 2022. Available: https://pure.tudelft.nl/ws/portalfiles/portal/217003316/3663529.3663862.pdf

---

## 📖 Citation

If you use this workflow in your research or HPC-related work, please cite:

Yagmur Kati. "Daylight-Controlled SLURM Workflow (Nextflow)." GitHub, 2025. https://github.com/YagmurKati/daylight-slurm-workflow

You can also use the following BibTeX entry:

```bibtex
@misc{kati2025daylightworkflow,
  author       = {Yagmur Kati},
  title        = {Daylight-Controlled SLURM Workflow (Nextflow)},
  year         = {2025},
  howpublished = {\url{https://github.com/YagmurKati/daylight-slurm-workflow}},
  note         = {GitHub repository}
}

---

## 📬 Contact

Questions or suggestions?
Contact: yagmur.kati@hu-berlin.de
