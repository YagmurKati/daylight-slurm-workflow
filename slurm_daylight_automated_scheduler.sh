#!/bin/bash

# --------------------------------------------
# SLURM Daylight Scheduler (Sunrise-aware)
# --------------------------------------------
# Schedules jobs to run preferentially during
# strong daylight hours (1h after sunrise to 1h before sunset).
# --------------------------------------------

LAT="52.52"
LNG="13.41"
TODAY=$(date +%Y-%m-%d)
LOGFILE="outtime.txt"
TMPFILE=$(mktemp)
JQ="$HOME/jq"  # Path to your local jq binary

log() {
  echo "[INFO] $1" >> "$LOGFILE"
}

# Start log
: > "$LOGFILE"
log "Starting daylight scheduler"

# Step 1: API request
curl -s "https://api.sunrise-sunset.org/json?lat=${LAT}&lng=${LNG}&date=${TODAY}&formatted=0" > "$TMPFILE"
log "Raw API response:"
cat "$TMPFILE" >> "$LOGFILE"

# Step 2: Extract status
status=$($JQ -r '.status' "$TMPFILE" 2>/dev/null)
log "API status: $status"

# Step 3: Extract sunrise/sunset
sunrise_utc=$($JQ -r '.results.sunrise' "$TMPFILE" | cut -d '+' -f1)
sunset_utc=$($JQ -r '.results.sunset' "$TMPFILE" | cut -d '+' -f1)

# Step 4: Convert to epoch (adjust to skip weak light periods)
sunrise_epoch=""
sunset_epoch=""
if [[ -n "$sunrise_utc" && -n "$sunset_utc" ]]; then
  sunrise_epoch=$(( $(date -d "$sunrise_utc" +%s) + 3600 ))
  sunset_epoch=$(( $(date -d "$sunset_utc" +%s) - 3600 ))
fi

now_epoch=$(date +%s)
sunriset=$(date -d "@$sunrise_epoch" +%Y-%m-%dT%H:%M:%S 2>/dev/null)
sunsett=$(date -d "@$sunset_epoch" +%Y-%m-%dT%H:%M:%S 2>/dev/null)
now_fmt=$(date -d "@$now_epoch")

log "Sunrise (local +1h): $sunriset"
log "Sunset  (local -1h): $sunsett"
log "Current time:        $now_fmt"

# Step 5: Handle API failures
if [[ "$status" != "OK" || -z "$sunriset" || -z "$sunsett" ]]; then
  if [[ -n "$sunrise_utc" ]]; then
    sunrise_epoch=$(( $(date -d "$sunrise_utc" +%s) + 3600 ))
    fallback=$(date -d "@$sunrise_epoch" +%Y-%m-%dT%H:%M:%S)
    log "API error but sunrise available - fallback to: $fallback"
  else
    fallback=$(date -d "07:00 today" +%Y-%m-%dT%H:%M:%S)
    log "API error and sunrise missing - fallback to hardcoded: $fallback"
  fi
  echo "--begin=$fallback"
  rm "$TMPFILE"
  exit 0
fi

# Step 6: Daylight logic
if [[ "$now_epoch" -ge "$sunrise_epoch" && "$now_epoch" -lt "$sunset_epoch" ]]; then
  log "Daylight condition met - run immediately"
  echo ""
else
  if [[ "$now_epoch" -lt "$sunrise_epoch" ]]; then
    log "Before sunrise - delaying to $sunriset"
    echo "--begin=$sunriset"
  else
    # After sunset - check tomorrow
    response_tomorrow=$(curl -s "https://api.sunrise-sunset.org/json?lat=${LAT}&lng=${LNG}&date=tomorrow&formatted=0")
    sunrise_tomorrow=$($JQ -r '.results.sunrise' <<< "$response_tomorrow" | cut -d '+' -f1)
    sunrise_tomorrow_epoch=$(( $(date -d "$sunrise_tomorrow" +%s) + 3600 ))
    sunrise_tomorrow_fmt=$(date -d "@$sunrise_tomorrow_epoch" +%Y-%m-%dT%H:%M:%S)
    log "After sunset - delaying to tomorrow's sunrise: $sunrise_tomorrow_fmt"
    echo "--begin=$sunrise_tomorrow_fmt"
  fi
fi

log "Script finished"
rm "$TMPFILE"

