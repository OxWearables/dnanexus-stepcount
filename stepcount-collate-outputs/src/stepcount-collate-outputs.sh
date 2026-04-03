#!/bin/bash

set -euo pipefail -E

main() {

    echo Input file ID: "$input_file"

    local_input_file=$(dx describe "$input_file" --name)
    echo Input file name: "$local_input_file"

    dx download "$input_file" -o "$local_input_file"

    fail_file=$(mktemp -u)  # sentinel path; created only on failure
    download() {
        local path="$1"
        path=${path%$'\r'}
        # Download into a per-file-ID subdirectory to avoid basename collisions
        local file_id="${path##*:}"
        local dest="files/$file_id"
        mkdir -p "$dest"
        local max_retries=3
        local attempt=1
        local delay=5
        while (( attempt <= max_retries )); do
            if dx download "$path" -o "$dest/" -f --lightweight; then
                return 0
            fi
            echo "WARN: attempt $attempt/$max_retries failed for $path, retrying in ${delay}s..." >&2
            sleep $delay
            attempt=$((attempt + 1))
            delay=$((delay * 2))
        done
        echo "FAILED after $max_retries attempts: $path" >&2
        touch "$fail_file"
        return 1
    }

    echo "Downloading files listed in $local_input_file..."
    mkdir -p files/
    max_jobs=16
    current=0
    total=$(awk 'END{print NR}' "$local_input_file")
    if (( total == 0 )); then
        echo "ERROR: Input file is empty." >&2
        exit 1
    fi
    next_pct=10
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ -n $line ]] || continue
        current=$((current+1))
        curr_pct=$((current * 100 / total))
        if (( curr_pct >= next_pct )) || (( current == total )); then
            echo "Progress: $current/$total..."
            next_pct=$((next_pct + 10))
        fi
        download "$line" &
        if (( $(jobs -rp | wc -l) >= max_jobs )); then
            wait -n
        fi
    done < "$local_input_file"
    wait

    if [ -f "$fail_file" ]; then
        echo "ERROR: One or more downloads failed." >&2
        rm -f "$fail_file"
        exit 1
    fi
    echo "Finished downloading files."

    # Background monitor: log memory and disk usage every 5 minutes
    (
        while true; do
            echo "--- Monitor $(date) ---"
            free -h
            df -h .
            sleep 300
        done
    ) &
    monitor_pid=$!
    trap 'kill $monitor_pid 2>/dev/null || true' EXIT

    stepcount-collate-outputs files/

    mkdir -p ~/out/outputs/
    mv collated-outputs ~/out/outputs/
    dx-upload-all-outputs

}
