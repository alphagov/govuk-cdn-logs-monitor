#!/bin/sh

usage="
Example usage:
  $(basename "$0") -h
  $(basename "$0") [log-directory [csv-directory]]

where:
  -h             show this help text
  log-directory  path to the directory where the compressed logs are stored
  csv-directory  path to the directory where the processed csv files are stored
"

option="${1}"

if [ "$option" = "-h" ]; then
    echo "$usage"
    exit 0
fi

# accept a source and output directory to get and store the processed logs
logdir="${1}"
if [ -z "${logdir}" ]; then
    logdir="${GOVUK_CDN_LOG_DIR}"
fi
if [ ! -e "${logdir}" ]; then
    echo "${logdir} not found"
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

for f in $logdir/*.gz; do
    # expect name to be formatted: cdn-govuk.log-YYYYMMDD.gz
    # extract YYYYMMDD part of zipped file name
    outfile=$(basename "$f" | awk '{print $4}' FS='-|\\.')

    # stop processing this file if the output already exists
    if [ -f "$csvdir/$outfile.csv" ]; then
        echo "$csvdir/$outfile.csv already exists"
    else
        echo "creating $csvdir/$outfile.csv"
        gunzip "$f" -c | ruby lib/process_200s_from_cdn_log.rb "$csvdir/$outfile.csv"
    fi
done
