#!/bin/bash

LOG_FILE="/var/log/tig_cpu_monitor.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "datetime,cpu_percentage" > "$LOG_FILE"
fi

while true; do
    cpu_usage=$(ps -eo pid,%cpu,cmd --sort=-%cpu | grep tig-worker | grep -v grep | awk '{print $2}')
    
    if [ -n "$cpu_usage" ]; then
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$timestamp,$cpu_usage" >> "$LOG_FILE"
    fi

    sleep 1
done

# Log CSV header if file does not exist
if [ ! -f "$LOG_FILE" ]; then
    echo "datetime,cpu_percentage" > "$LOG_FILE"
fi

# Check if tig-worker process is running and get its CPU usage
cpu_usage=$(ps -eo pid,%cpu,cmd --sort=-%cpu | grep tig-worker | grep -v grep | awk '{print $2}')

if [ -n "$cpu_usage" ]; then
    # Get the current date and time
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Log the timestamp and CPU usage
    echo "$timestamp,$cpu_usage" >> "$LOG_FILE"
fi
