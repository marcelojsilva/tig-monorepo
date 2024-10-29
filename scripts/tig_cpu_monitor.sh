#!/bin/bash

LOG_FILE="/var/log/tig_cpu_monitor.log"

# Log CSV header if file does not exist
if [ ! -f "$LOG_FILE" ]; then
    echo "datetime,cpu_usage,gpu_usage" > "$LOG_FILE"
fi

while true; do
    # Check if tig-worker process is running
    if pgrep -x "tig-worker" > /dev/null; then
        # Collect per-CPU usage data
        cpu_usages=$(mpstat -P ALL 1 1 | awk '/^Average/ && $2 ~ /[0-9]+/ { printf "CPU%s: %.2f%% | ", $2, 100 - $12 } END { print "" }')
        
        # Collect GPU usage data if nvidia-smi is available
        if command -v nvidia-smi &> /dev/null; then
            gpu_usages=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{printf "GPU%d: %s%% | ", NR-1, $1}')
        else
            gpu_usages="No GPUs"
        fi
        
        # Log CPU and GPU usage if either is present
        if [ -n "$cpu_usages" ] || [ -n "$gpu_usages" ]; then
            timestamp=$(date +"%Y-%m-%d %H:%M:%S")
            echo "$timestamp,$cpu_usages,$gpu_usages" >> "$LOG_FILE"
        fi
    fi

    # Wait 1 second before the next check
    sleep 1
done
