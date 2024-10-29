#!/bin/bash

LOG_FILE="/var/log/tig_log_algorithms_benchmark.csv"

# Check for required environment variables, setting default only if needed
VM_FLAVOUR="${VM_FLAVOUR}"
NUM_GPUS="${NUM_GPUS}"
NUM_CPUS="${NUM_CPUS}"
DIFFICULTY="${DIFFICULTY}"
START_NONCE="${START_NONCE}"
NUM_NONCES="${NUM_NONCES}"
NUM_WORKERS="${NUM_WORKERS}"
CHALLENGE_NAME="${CHALLENGE_NAME}"

# Define repo and tig-worker paths
REPO_DIR=$(dirname $(dirname "$(realpath "$0")"))
TIG_WORKER_PATH="$REPO_DIR/target/release/tig-worker"

# Check if tig-worker binary exists
if [ ! -f "$TIG_WORKER_PATH" ]; then
    echo "Error: tig-worker binary not found at $TIG_WORKER_PATH" | systemd-cat -t tig_log_algorithms_benchmark -p err
    exit 1
else
    echo "Found tig-worker binary at $TIG_WORKER_PATH" | systemd-cat -t tig_log_algorithms_benchmark -p info
fi

# Verify if the challenge directory exists
CHALLENGE_PATH="$REPO_DIR/tig-algorithms/wasm/$CHALLENGE_NAME"
if [ ! -d "$CHALLENGE_PATH" ]; then
    echo "Error: Challenge '$CHALLENGE_NAME' directory not found at $CHALLENGE_PATH" | systemd-cat -t tig_log_algorithms_benchmark -p err
    exit 1
else
    echo "Challenge directory found at $CHALLENGE_PATH" | systemd-cat -t tig_log_algorithms_benchmark -p info
fi

# Log CSV header if file does not exist
if [ ! -f "$LOG_FILE" ]; then
    echo "Creating log file with headers at $LOG_FILE" | systemd-cat -t tig_log_algorithms_benchmark -p info
    echo "Timestamp,VM_Flavour,Num_GPUs,Num_CPUs,Challenge_ID,Challenge_Name,Difficulty,Algorithm_ID,Start_Time,End_Time,Duration,Nonce,Solutions_Count,Invalid_Count,Output_Stdout,Output_Stderr" > "$LOG_FILE"
fi

# Loop through all .wasm algorithms in the specified challenge directory
for wasm_file in "$CHALLENGE_PATH"/*.wasm; do
    if [ -f "$wasm_file" ]; then
        ALGORITHM=$(basename "$wasm_file" .wasm)
        echo "Testing algorithm: $ALGORITHM for challenge: $CHALLENGE_NAME" | systemd-cat -t tig_log_algorithms_benchmark -p info

        # Map CHALLENGE ID based on the challenge name
        case $CHALLENGE_NAME in
            satisfiability) CHALLENGE_ID="c001" ;;
            vehicle_routing) CHALLENGE_ID="c002" ;;
            knapsack) CHALLENGE_ID="c003" ;;
            vector_search) CHALLENGE_ID="c004" ;;
            *) echo "Error: Challenge '$CHALLENGE_NAME' is not recognized." | systemd-cat -t tig_log_algorithms_benchmark -p err ; exit 1 ;;
        esac

        # Initialize test parameters
        remaining_nonces=$NUM_NONCES
        current_nonce=$START_NONCE

        # Run test for each algorithm
        while [ $remaining_nonces -gt 0 ]; do
            nonces_to_compute=$((NUM_WORKERS < remaining_nonces ? NUM_WORKERS : remaining_nonces))
            start_time=$(date +%s%3N)
            stdout=$(mktemp)
            stderr=$(mktemp)
            timestamp=$(date +"%Y-%m-%d %H:%M:%S")

            echo "Executing tig-worker with $nonces_to_compute nonces, starting at nonce $current_nonce" | systemd-cat -t tig_log_algorithms_benchmark -p info

            # Escape double quotes in the settings JSON to avoid parsing errors
            SETTINGS="{\"challenge_id\":\"$CHALLENGE_ID\",\"difficulty\":$DIFFICULTY,\"algorithm_id\":\"$ALGORITHM\",\"player_id\":\"\",\"block_id\":\"\"}"

            # Execute tig-worker with specified parameters
            $TIG_WORKER_PATH compute_batch \
                "$SETTINGS" \
                "random_string" $current_nonce $nonces_to_compute $nonces_to_compute \
                "$wasm_file" --workers $nonces_to_compute >"$stdout" 2>"$stderr"

            end_time=$(date +%s%3N)
            duration=$((end_time - start_time))
            output_stdout=$(cat "$stdout")
            output_stderr=$(cat "$stderr")

            solutions_count=$(echo "$output_stdout" | grep -o '"solution_nonces":\[.*\]' | sed 's/.*\[\(.*\)\].*/\1/' | awk -F',' '{print NF}')
            invalid_count=$((nonces_to_compute - solutions_count))

            echo "Run complete for $ALGORITHM, duration: $duration ms" | systemd-cat -t tig_log_algorithms_benchmark -p info

            # Write to CSV log with timestamp as the first column
            echo "$timestamp,$VM_FLAVOUR,$NUM_GPUS,$NUM_CPUS,$CHALLENGE_ID,$CHALLENGE_NAME,$DIFFICULTY,$ALGORITHM,$start_time,$end_time,$duration,$current_nonce,$solutions_count,$invalid_count,\"$output_stdout\",\"$output_stderr\"" >> "$LOG_FILE"

            # Clean up temporary files
            rm "$stdout" "$stderr"

            current_nonce=$((current_nonce + nonces_to_compute))
            remaining_nonces=$((remaining_nonces - nonces_to_compute))
        done
    fi
done

echo "Testing complete for all algorithms in challenge '$CHALLENGE_NAME'. Results logged to $LOG_FILE." | systemd-cat -t tig_log_algorithms_benchmark -p info
