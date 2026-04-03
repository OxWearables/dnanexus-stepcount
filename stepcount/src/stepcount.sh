#!/bin/bash

set -euo pipefail

retry() {
    local max_retries=3 attempt=1 delay=5
    while (( attempt <= max_retries )); do
        if "$@"; then return 0; fi
        echo "WARN: attempt $attempt/$max_retries failed, retrying in ${delay}s..." >&2
        sleep $delay
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done
    echo "FAILED after $max_retries attempts: $*" >&2
    return 1
}

main() {

    echo Input file ID: "$input_file"

    local_input_file=$(retry dx describe "$input_file" --name)
    echo Input file name: "$local_input_file"

    retry dx download "$input_file" -o "$local_input_file" -f

    cmd=(stepcount "$local_input_file" --model-type "$model_type")
    if [ -n "$exclude_first_last" ]; then
        cmd+=(--exclude-first-last "$exclude_first_last")
    fi
    if [ -n "$exclude_wear_below" ]; then
        cmd+=(--exclude-wear-below "$exclude_wear_below")
    fi
    if [ -n "${min_wear_per_day:-}" ]; then
        cmd+=(--min-wear-per-day "$min_wear_per_day")
    fi
    if [ -n "$start" ]; then
        cmd+=(--start "$start")
    fi
    if [ -n "$end" ]; then
        cmd+=(--end "$end")
    fi

    echo "Running: ${cmd[*]}"
    "${cmd[@]}"

    mkdir -p ~/out/outputs/
    mv outputs ~/out/outputs/
    dx-upload-all-outputs

}
