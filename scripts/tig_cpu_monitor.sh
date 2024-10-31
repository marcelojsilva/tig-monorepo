#!/bin/bash

LOG_FILE="/var/log/tig_cpu_monitor.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "datetime;cpu_percentage" > "$LOG_FILE"
fi

while true; do
    # Check if tig-worker process is running
    if pgrep -x "tig-worker" > /dev/null; then
        # Collect per-CPU usage data
        cpu_usages=$(mpstat -P ALL 1 1 | awk '/^Average/ && $2 ~ /[0-9]+/ { printf "CPU%s: %.2f%% | ", $2, 100 - $12 } END { print "" }')
        
        if [ -n "$cpu_usages" ]; then
            timestamp=$(date +"%Y-%m-%d %H:%M:%S")
            echo "$timestamp;$cpu_usages" >> "$LOG_FILE"
        fi
    fi

    # Wait 1 second before next check
    sleep 1
done