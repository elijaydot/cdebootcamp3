#!/bin/bash

# ============================================================
# ETL Script for CoreDataEngineers Assignment
# This script performs Extract, Transform, and Load
# ============================================================

# ---------- Environment Variable for the CSV URL ----------
export CSV_URL="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv"

# ---------- Define folder paths ----------
RAW_DIR="raw"
TRANSFORMED_DIR="Transformed"
GOLD_DIR="Gold"
RAW_FILE="$RAW_DIR/annual-enterprise-survey-2023-financial-year-provisional.csv"
TRANSFORMED_FILE="$TRANSFORMED_DIR/2023_year_finance.csv"
GOLD_FILE="$GOLD_DIR/2023_year_finance.csv"

echo "=============================================="
echo "Starting ETL Process..."
echo "=============================================="

# ============================================================
# 1. EXTRACT
# Download the CSV file and save it into the raw folder
# ============================================================
echo ""
echo ">>> EXTRACT STEP: Downloading CSV file..."

# Create the raw folder if it does not exist
# -p, or --parents (parents option), creates missing parent directories and
# does not fail if the folder already exists.
mkdir -p "$RAW_DIR"

# Download the file using the environment variable
# --fail, or -f (fail option), makes curl return an error for HTTP failures.
# --location, or -L (location option), follows redirects from the data provider.
# --output, or -o (output option), writes the download to the following path.
if ! curl --fail --location --output "$RAW_FILE" "$CSV_URL"; then
    echo "ERROR: Download failed. Check the URL and your network connection."
    exit 1
fi

# Check if the file was downloaded successfully
# -s (file-size test operator) is true only when the file exists and is not empty.
if [ -s "$RAW_FILE" ]; then
    echo "SUCCESS: File has been saved in the raw folder."
    echo "File location: $RAW_FILE"
else
    echo "ERROR: Download failed. The raw file is missing or empty."
    exit 1
fi

# ============================================================
# 2. TRANSFORM
# - Rename column Variable_code to variable_code
# - Keep only columns: year, Value, Units, variable_code
# - Save as 2023_year_finance.csv in Transformed folder
# ============================================================
echo ""
echo ">>> TRANSFORM STEP: Cleaning and selecting columns..."

# Create the Transformed folder if it does not exist
# -p, or --parents (parents option), creates the folder when needed and does
# not fail if the folder already exists.
mkdir -p "$TRANSFORMED_DIR"

# Use awk to:
# 1. Rename Variable_code → variable_code
# 2. Select only the required columns
# 3. Change Year → year (to match the requirement)
# The source currently stores Year, Value, Units, and Variable_code in columns
# 1, 9, 5, and 6; these positions explain the original awk selection above.
# A plain awk comma separator cannot distinguish delimiter commas from commas
# inside quoted CSV values. Python's csv module handles those values correctly
# and selects columns by header name, so source column order can safely change.
# - (standard-input marker) tells Python to read the program from the heredoc.
if ! python3 - "$RAW_FILE" "$TRANSFORMED_FILE" <<'PY'
import csv
import sys

raw_file, transformed_file = sys.argv[1:]

with open(raw_file, newline="", encoding="utf-8-sig") as source_file:
    reader = csv.DictReader(source_file)
    required_columns = ("Year", "Value", "Units", "Variable_code")
    missing_columns = [name for name in required_columns if name not in reader.fieldnames]
    if missing_columns:
        raise ValueError(f"Missing required columns: {', '.join(missing_columns)}")

    with open(transformed_file, "w", newline="", encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(("year", "Value", "Units", "variable_code"))
        writer.writerows(
            (row["Year"], row["Value"], row["Units"], row["Variable_code"])
            for row in reader
        )
PY
then
    echo "ERROR: Transformation command failed."
    exit 1
fi

# Check if the transformed file was created
# -s (file-size test operator) confirms the file exists and is not empty.
if [ -s "$TRANSFORMED_FILE" ]; then
    echo "SUCCESS: Transformed file has been saved in the Transformed folder."
    echo "File location: $TRANSFORMED_FILE"
else
    echo "ERROR: Transformation failed. The transformed file is missing or empty."
    exit 1
fi

# ============================================================
# 3. LOAD
# Copy the transformed file into the Gold folder
# ============================================================
echo ""
echo ">>> LOAD STEP: Loading data into Gold folder..."

# Create the Gold folder if it does not exist
# -p, or --parents (parents option), avoids an error when the folder exists.
mkdir -p "$GOLD_DIR"

# Copy the transformed file to Gold
if ! cp "$TRANSFORMED_FILE" "$GOLD_FILE"; then
    echo "ERROR: Could not copy the transformed file into the Gold folder."
    exit 1
fi

# Check if the file was loaded successfully
# -s (file-size test operator) confirms the Gold file exists and is not empty.
if [ -s "$GOLD_FILE" ]; then
    echo "SUCCESS: File has been saved in the Gold folder."
    echo "File location: $GOLD_FILE"
else
    echo "ERROR: Load step failed. The Gold file is missing or empty."
    exit 1
fi

echo ""
echo "=============================================="
echo "ETL Process Completed Successfully!"
echo "=============================================="