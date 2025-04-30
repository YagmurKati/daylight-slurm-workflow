#!/bin/bash

# --------------------------------------------
# SLURM Daylight Scheduler
# --------------------------------------------
# This script outputs a '--begin=...' SLURM directive
# to delay job start until the next available daylight window (07:00–19:00).
#
# If it's already daylight, it allows the job to start immediately.
# If it's outside daylight hours, it delays the job to the next daylight start time.
#
# IMPORTANT: This delay happens only once. If the job is still waiting when daylight ends,
# it will run as soon as resources are available, even outside daylight hours.
# --------------------------------------------

# Get current time as HHMM (e.g., 1045, 1830)
now=$(date +%H%M)

# Define daylight window
daylight_start=0700
daylight_end=1900

if [ "$now" -ge "$daylight_start" ] && [ "$now" -lt "$daylight_end" ]; then
    # It is already daylight - allow immediate job start
    echo ""
else
    if [ "$now" -lt "$daylight_start" ]; then
        # Before daylight - delay to today at 07:00
        TIME=$(date -d "07:00 today" +%Y-%m-%dT%H:%M:%S)
    else
        # After daylight - delay to 07:00 next day
        TIME=$(date -d "07:00 next day" +%Y-%m-%dT%H:%M:%S)
    fi
    echo "--begin=${TIME}"
fi

