#!/bin/bash

# Function to calculate directory size recursively
get_directory_size() {
    local dir_path="$1"
    local total_size=0

    # Loop through files and directories
    while IFS= read -r -d '' entry; do
        if [ -f "$entry" ]; then
            # Add size of regular file
            total_size=$((total_size + $(stat -c "%s" "$entry")))
        elif [ -d "$entry" ]; then
            # Add size of subdirectory (recursive call)
            total_size=$((total_size + $(get_directory_size "$entry")))
        fi
    done < <(find "$dir_path" -mindepth 1 -maxdepth 1 -print0)

    echo "$total_size"
}

# Function to search for directories named by the user input recursively
search_directories() {
    local search_path="$1"
    local target_dir="$2"
    local total_size=0

    # Loop through directories
    while IFS= read -r -d '' directory; do
        if [ -d "$directory" ]; then
            # Check if directory matches the target directory name
            if [ "$(basename "$directory")" = "$target_dir" ]; then
                # Get size of the target directory
                dir_size=$(get_directory_size "$directory")
                echo "Directory: $directory - Size: $dir_size bytes"
                total_size=$((total_size + dir_size))
            fi
        fi
    done < <(find "$search_path" -type d -name "$target_dir" -print0)

    echo "Aggregate size of '$target_dir' directories: $total_size bytes"
}

# Parse command line options
while getopts ":p:n:" opt; do
    case $opt in
        p) search_path=$OPTARG ;;
        n) target_name=$OPTARG ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
done

# Check if required options are provided
if [[ -z $search_path || -z $target_name ]]; then
    echo "Usage: $0 -p <search_directory> -n <target_directory_name>"
    exit 1
fi

# Search directories
search_directories "$search_path" "$target_name"
