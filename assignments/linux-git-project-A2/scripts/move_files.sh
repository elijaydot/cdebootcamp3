#!/bin/bash

# ============================================================
# Script to move all CSV and JSON files into json_and_CSV folder
# ============================================================

# Folder where we will move the files
DEST_DIR="json_and_CSV"

# Ask where the destination folder should be created. Pressing Enter keeps it
# in the current directory, which matches the script's original behavior.
printf "Where should the %s folder be created? [current directory]: " "$DEST_DIR"
# -r, or --raw (raw input option), keeps backslashes in the entered path unchanged.
if ! read -r DEST_PARENT; then
    echo "ERROR: Could not read the destination location."
    exit 1
fi
# ${DEST_PARENT:-.} uses . (the current directory) when no path is entered.
DEST_PARENT="${DEST_PARENT:-.}"
DEST_DIR="$DEST_PARENT/$DEST_DIR"

# Create the destination folder if it does not exist
# -p, or --parents (parents option), creates the folder when needed and does
# not return an error if the folder already exists.
if ! mkdir -p "$DEST_DIR"; then
    echo "ERROR: Could not create the destination folder: $DEST_DIR"
    exit 1
fi

# Convert the destination to an absolute path so find can reliably exclude it,
# including when it is placed inside a subfolder of the current directory.
# -P (physical option) resolves symbolic links while determining the path.
DEST_DIR="$(cd "$DEST_DIR" && pwd -P)"
# Record the current directory as an absolute path so it uses the same path
# format as DEST_DIR when find applies the exclusion rule.
SOURCE_DIR="$(pwd -P)"

echo "=============================================="
echo "Starting file move process..."
echo "=============================================="

# Counter for moved files
count=0
# Track files that are not moved because the destination already has that name.
skipped=0
# Track move errors separately so the final summary reports incomplete work.
failed=0

# Find and move all .csv and .json files from the current directory
# (and subfolders if needed). We exclude the destination folder itself.
# find expressions used below:
# -type f selects regular files; -name matches a filename pattern.
# -o is the OR operator, so either the CSV or JSON pattern can match.
# ! -path excludes paths inside the selected destination folder.
# -print0 separates results with a null byte so spaces and newlines in filenames
# are preserved. The escaped parentheses group the two filename patterns.
# read -r (raw option) keeps backslashes unchanged, and -d (delimiter option)
# with an empty value reads each filename up to the null byte from find.
while IFS= read -r -d '' file; do
    # -f (regular-file test operator) confirms the path is still a regular file.
    if [ -f "$file" ]; then
        destination="$DEST_DIR/${file##*/}"

        # -e (exists test operator) prevents a same-named file from being replaced.
        if [ -e "$destination" ]; then
            echo "Skipping: $file (a file named ${file##*/} already exists)"
            skipped=$((skipped + 1))
        else
            echo "Moving: $file"
            # -- (end-of-options marker) ensures filenames beginning with a hyphen
            # are treated as paths rather than mv command options.
            if mv -- "$file" "$DEST_DIR/"; then
                count=$((count + 1))
            else
                echo "ERROR: Could not move $file"
                failed=$((failed + 1))
            fi
        fi
    fi
# done < <(find . -type f \( -name "*.csv" -o -name "*.json" \) ! -path "./$DEST_DIR/*" -print0)
done < <(find "$SOURCE_DIR" -type f \( -name "*.csv" -o -name "*.json" \) ! -path "$DEST_DIR/*" -print0)

echo ""
echo "=============================================="
# -eq (numeric equality operator) checks whether the moved-file count equals zero.
if [ "$count" -eq 0 ] && [ "$skipped" -eq 0 ] && [ "$failed" -eq 0 ]; then
    echo "No CSV or JSON files found to move."
else
    echo "Successfully moved $count file(s) into $DEST_DIR folder."
fi
# -gt (numeric greater-than operator) checks whether any files were skipped.
if [ "$skipped" -gt 0 ]; then
    echo "Skipped $skipped file(s) because the destination name already exists."
fi
if [ "$failed" -gt 0 ]; then
    echo "Failed to move $failed file(s)."
fi
echo "=============================================="

# Show what is now inside the destination folder
echo ""
echo "Contents of $DEST_DIR folder:"
# -l, or --format=long (long-format option), shows file details; -h, or
# --human-readable, displays file sizes using readable units such as KB and MB.
ls -lh "$DEST_DIR"