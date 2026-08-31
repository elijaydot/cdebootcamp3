# Linux and Git Project

A practical data engineering project built with Bash, Linux utilities, and
Python's standard CSV library. It automates an ETL workflow and organizes CSV
and JSON files with clear validation, safe path handling, and readable output.

## What Was Built

### ETL Pipeline

The `scripts/etl.sh` script performs three stages:

1. Extracts the Annual Enterprise Survey CSV file from Stats NZ into `raw/`.
2. Transforms the source data by selecting `year`, `Value`, `Units`, and
	`variable_code`, then saves the result in `Transformed/`.
3. Loads a copy of the transformed dataset into `Gold/`.

The transformation uses Python's CSV module so quoted values containing commas
are handled correctly. Each stage checks for command failures and verifies that
its output file exists and is not empty.

#### Important Parts of the ETL Script

- `CSV_URL` stores the web address of the source file. Keeping it in a variable
	means the address only needs to be changed in one place.
- `RAW_DIR`, `TRANSFORMED_DIR`, and `GOLD_DIR` store the folder names used by
	the pipeline. The file paths are built from these variables.
- `mkdir -p` creates each required folder. The `-p` option prevents an error if
	the folder already exists.
- `curl` downloads the dataset. Its options detect web errors, follow redirects,
	and save the response using the required filename.
- `[ -s "$FILE" ]` checks that a file exists and contains data. This stops the
	pipeline from treating a missing or empty file as a successful result.
- Python's `csv.DictReader` reads each row using column names instead of fixed
	column positions. This makes the transformation easier to understand and less
	likely to break if the source columns are rearranged.
- The script checks that all required columns exist before creating the output.
	It then writes only `year`, `Value`, `Units`, and `variable_code`.
- `cp` loads the finished file into `Gold/`. If any major command fails,
	`exit 1` stops the script and tells the operating system that an error occurred.

### File Organizer

The `scripts/move_files.sh` script searches the current directory and its
subdirectories for CSV and JSON files. It asks where the `json_and_CSV` folder
should be created, with the current directory used when no location is entered.

The script safely handles filenames containing spaces or backslashes, excludes
the destination from future searches, prevents existing files from being
overwritten, and reports moved, skipped, and failed files separately.

#### Important Parts of the File Organizer

- `DEST_DIR` stores the destination folder name, `json_and_CSV`.
- `read -r` asks the user where to create that folder. Pressing Enter uses `.`,
	which means the current directory.
- `SOURCE_DIR` records the directory where the script was started. This is the
	folder that `find` searches, including all of its subdirectories.
- `pwd -P` creates full, absolute paths. Using full paths helps the script tell
	the source and destination apart even when the destination is nested inside
	the source directory.
- `find` selects regular files ending in `.csv` or `.json` and excludes files
	already inside the destination folder.
- `-print0` and `read -d ''` pass filenames using a special null separator.
	Unlike spaces or new lines, this separator can safely handle unusual filenames.
- `[ -e "$destination" ]` checks whether a file with the same name is already
	present. If it is, the source file is skipped instead of replacing it.
- `mv --` moves each file. The `--` marks the end of command options, so a
	filename beginning with a hyphen is not mistaken for an option.
- The `count`, `skipped`, and `failed` variables track what happened and produce
	a clear summary when the process finishes.

### Scheduled Automation

The `cron_job.txt` file contains a cron entry for running the ETL pipeline
automatically every day at midnight:

```cron
0 0 * * * /absolute/path/to/scripts/etl.sh >> /absolute/path/to/etl_cron.log 2>&1
```

```text
the fields are: Minute Hour Day Month DayOfWeek
means:
Minute = 0
Hour = 0 (midnight)
Every day of month
Every month
Every day of week

Translation:
Run the script every day at 12:00 AM (midnight).
```

The five schedule fields represent minute, hour, day of the month, month, and
day of the week. The values `0 0 * * *` mean midnight on every day. The `>>`
operator appends normal output to `etl_cron.log`, while `2>&1` sends errors to
the same log file.

Before installing the entry with `crontab`, replace the paths stored in
`cron_job.txt` with the absolute paths for this `linux-git-project-A2`
directory. Cron may start commands from another working directory, so the ETL
script should also change to the project directory before using relative paths.

## Project Structure

```text
linux-git-project-A2/
|-- Gold/              Final ETL output
|-- Transformed/       Cleaned and selected data
|-- json_and_CSV/      Organized CSV and JSON files
|-- raw/               Downloaded source data
|-- scripts/
|   |-- etl.sh         Extract, transform, and load workflow
|   `-- move_files.sh  CSV and JSON file organizer
|-- cron_job.txt       Cron scheduling reference
`-- README.md
```

## Requirements

- Bash
- `curl`
- Python 3
- Standard Linux commands including `find`, `mv`, `mkdir`, and `ls`

## Usage

Run commands from the `linux-git-project-A2` directory so relative paths are
created in the expected location.

```bash
./scripts/etl.sh
```

To organize CSV and JSON files from a chosen search directory, change to that
directory and call the script using its relative or absolute path:

```bash
../scripts/move_files.sh
```

When prompted, enter the parent directory where `json_and_CSV` should be
created, or press Enter to use the current directory.

## Key Outcomes

- Automated extraction, transformation, and loading of a public dataset
- Reliable parsing of CSV records containing quoted commas
- Safe recursive discovery and movement of CSV and JSON files
- Protection against accidental file replacement
- Daily ETL scheduling with combined output and error logging
- Clear comments explaining command flags and important Bash expressions
