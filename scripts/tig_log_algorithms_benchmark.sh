#!/bin/bash

# Script arguments for VM configuration and test parameters (set default values if not provided by environment variables)
VM_FLAVOUR="${VM_FLAVOUR:-n1-cpu-small}"
NUM_GPUS="${NUM_GPUS:-0}"
NUM_CPUS="${NUM_CPUS:-4}"
DIFFICULTY="${DIFFICULTY:-[10,350]}"  # Expected format: [x,y]
START_NONCE="${START_NONCE:-1}"
NUM_NONCES="${NUM_NONCES:-3}"
NUM_WORKERS="${NUM_WORKERS:-1}"
CHALLENGE_NAME="${CHALLENGE_NAME:-vector_search}"

# Define repo and tig-worker paths
REPO_DIR=$(dirname $(dirname "$(realpath "$0")"))
TIG_WORKER_PATH="$REPO_DIR/target/release/tig-worker"
LOG_FILE="/var/log/tig_log_algorithms_benchmark.csv"

# Check if tig-worker binary exists
if [ ! -f "$TIG_WORKER_PATH" ]; then
    echo "Error: tig-worker binary not found at $TIG_WORKER_PATH"
    echo "Run: cd $REPO_DIR && cargo build -p tig-worker --release"
    exit 1
fi

# Verify if the challenge directory exists
CHALLENGE_PATH="$REPO_DIR/tig-algorithms/wasm/$CHALLENGE_NAME"
if [ ! -d "$CHALLENGE_PATH" ]; then
    echo "Error: Challenge '$CHALLENGE_NAME' not found."
    exit 1
fi

# Log CSV header if file does not exist
if [ ! -f "$LOG_FILE" ]; then
    echo "Timestamp,VM_Flavour,Num_GPUs,Num_CPUs,Challenge_ID,Challenge_Name,Difficulty,Algorithm_ID,Start_Time,End_Time,Duration,Nonce,Solutions_Count,Invalid_Count,Output_Stdout,Output_Stderr" > "$LOG_FILE"
fi

# Loop through all .wasm algorithms in the specified challenge directory
for wasm_file in "$CHALLENGE_PATH"/*.wasm; do
    if [ -f "$wasm_file" ]; then
        ALGORITHM=$(basename "$wasm_file" .wasm)
        echo "Testing algorithm: $ALGORITHM for challenge: $CHALLENGE_NAME"

        # Map CHALLENGE ID based on the challenge name
        case $CHALLENGE_NAME in
            satisfiability) CHALLENGE_ID="c001" ;;
            vehicle_routing) CHALLENGE_ID="c002" ;;
            knapsack) CHALLENGE_ID="c003" ;;
            vector_search) CHALLENGE_ID="c004" ;;
            *) echo "Error: Challenge '$CHALLENGE_NAME' is not recognized." ; exit 1 ;;
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
            timestamp=$(date +"%Y-%m-%d %H:%M:%S")  # Capture current datetime

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

            # Write to CSV log with timestamp as the first column
            echo "$timestamp,$VM_FLAVOUR,$NUM_GPUS,$NUM_CPUS,$CHALLENGE_ID,$CHALLENGE_NAME,$DIFFICULTY,$ALGORITHM,$start_time,$end_time,$duration,$current_nonce,$solutions_count,$invalid_count,\"$output_stdout\",\"$output_stderr\"" >> "$LOG_FILE"

            # Clean up temporary files
            rm "$stdout" "$stderr"

            current_nonce=$((current_nonce + nonces_to_compute))
            remaining_nonces=$((remaining_nonces - nonces_to_compute))
        done
    fi
done

echo "Testing complete for all algorithms in challenge '$CHALLENGE_NAME'. Results logged to $LOG_FILE."
