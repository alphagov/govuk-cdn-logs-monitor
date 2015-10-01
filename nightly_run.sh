#!/bin/sh

usage="
Example usage:
  $(basename "$0") -h
  $(basename "$0") [log-directory [csv-directory]]

where:
  -h             show this help text
  log-directory  path to the directory where the uncompressed daily log is stored
  csv-directory  path to the directory where the processed csv files are stored
"

option="${1}"

if [ "$option" = "-h" ]; then
    echo "$usage"
    exit 0
fi

# find the newest uncompressed file from the log directory
logdir="${1}"
infile=$(ls -1tr $logdir/cdn-govuk.log-* | grep -v .gz | tail -1)

# expect name to be formatted: cdn-govuk.log-YYYYMMDD
# extract YYYYMMDD part of newest file
outfile=$(basename "$infile" | awk '{print $4}' FS='-|\\.')
if [ -z "${outfile}" ]; then
    echo "Date not found. Can't create output csv."
    exit 1
fi

csvdir="${2}"
if [ -z "${csvdir}" ]; then
    csvdir="${GOVUK_CDN_CSV_DIR}"
fi
if [ ! -e "${csvdir}" ]; then
    echo "${csvdir} not found"
    exit 1
fi

echo "This process is creating $csvdir/$outfile.csv"
ruby lib/process_200s_from_cdn_log.rb "$csvdir/$outfile.csv" < "$infile"
