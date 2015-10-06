#!/bin/sh

usage="
Example usage:
  $(basename "$0") -h
  $(basename "$0") [log-directory [processed-data]]

where:
  -h              show this help text
  log-directory   path to the directory where the uncompressed daily log is stored
  processed-data  path to the directory where the processed data files are stored
"

option="${1}"

if [ "$option" = "-h" ]; then
    echo "$usage"
    exit 0
fi

# find the newest uncompressed file from the log directory
logdir="${1}"
if [ -z "${logdir}" ]; then
    logdir="${GOVUK_CDN_LOG_DIR}"
fi
if [ ! -e "${logdir}" ]; then
    echo "${logdir} not found"
    exit 1
fi

infile=$(ls -1tr $logdir/cdn-govuk.log-* | grep -v .gz | tail -1)

# expect name to be formatted: cdn-govuk.log-YYYYMMDD
# extract YYYYMMDD part of newest file
day=$(basename "$infile" | awk '{print $4}' FS='-|\\.')
if [ -z "${day}" ]; then
    echo "Date not found. Can't create output csv."
    exit 1
fi

processeddata="${2}"
if [ -z "${processeddata}" ]; then
    processeddata="${GOVUK_PROCESSED_DATA_DIR}"
fi
if [ ! -e "${processeddata}" ]; then
    echo "${processeddata} not found"
    exit 1
fi

outfile="${processeddata}/${day}.csv"
echo "This process is creating ${outfile}"
ruby lib/process_200s_from_cdn_log.rb "${outfile}" < "${infile}"
