nextflow.enable.dsl = 2

// This process runs the daylight scheduler script and outputs SLURM --begin=... options
process calculate_daylight_start {
    input:
    path script, stageAs: 'slurm_daylight_scheduler.sh'

    output:
    stdout

    script:
    """
    bash slurm_daylight_scheduler.sh
    """
}

// High energy task using standard partition
// Will delay to daylight hours if submitted outside 07:00–19:00
process highenergy_std_task {
    label 'std_high_en_partition'

    input:
    val cluster_opts

    clusterOptions "${cluster_opts} --requeue"

    script:
    """
    echo 'Running high energy task (daylight preferred)'
    echo "Cluster options received: $cluster_opts"
    sleep 30
    """
}

// Standard task with moderate resource use
process standard_task {
    label 'standard_partition'
    script:
    """
    echo 'Running standard task'
    sleep 30
    """
}

// Long-running task on longrun partition
process longrun_task {
    label 'longrun_partition'
    script:
    """
    echo 'Running longrun task'
    sleep 30
    """
}

// High memory task on large_memory partition
// Will delay to daylight hours if submitted outside 07:00–19:00
process highenergy_memory_task {
    label 'large_memory_partition'

    input:
    val cluster_opts

    clusterOptions "${cluster_opts} --requeue"

    script:
    """
    echo 'Running large memory task'
    echo "Cluster options received: $cluster_opts"
    sleep 30
    """
}

// GPU task (uses daylight scheduling logic)
process gpu_task {
    label 'gpu_partition'

    input:
    val cluster_opts

    clusterOptions "${cluster_opts} --requeue"

    script:
    """
    echo 'Running GPU task (daylight preferred)'
    echo "Cluster options received: $cluster_opts"
    sleep 30
    """
}


// Main workflow
workflow {
    cluster_options_ch = calculate_daylight_start(file('slurm_daylight_scheduler.sh'))

    highenergy_std_task(cluster_options_ch)
    standard_task()
    longrun_task()

    // Uncomment the following lines to enable these optional processes:
    // These use the large_memory and gpu partitions,
    // which are often full or limited and not ideal for quick testing.

    // highenergy_memory_task(cluster_options_ch)
    // gpu_task(cluster_options_ch)
}

