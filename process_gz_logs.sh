#!/bin/sh

usage="
Example usage:
  $(basename "$0") -h
  $(basename "$0") [log-directory [processed-data]]

where:
  -h              show this help text
  log-directory   path to the directory where the compressed logs are stored
                  defaults to $GOVUK_CDN_LOG_DIR environment variable
  processed-data  path to the directory where the processed csv files are stored
                  defaults to $GOVUK_PROCESSED_DATA_DIR environment variable
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

processeddata="${2}"
if [ -z "${processeddata}" ]; then
    processeddata="${GOVUK_PROCESSED_DATA_DIR}"
fi
if [ ! -e "${processeddata}" ]; then
    echo "${processeddata} not found"
    exit 1
fi

for f in $logdir/*.gz; do
    # expect name to be formatted: cdn-govuk.log-YYYYMMDD.gz
    # extract YYYYMMDD part of zipped file name
    day=$(basename "${f}" | awk '{print $4}' FS='-|\\.')

    outfile="${processeddata}/${day}.csv"

    # stop processing this file if the output already exists
    if [ -f "${outfile}" ]; then
        echo "${outfile} already exists"
    else
        echo "creating ${outfile}"
        gunzip "$f" -c | bundle exec ruby lib/process_200s_from_cdn_log.rb "${outfile}"
    fi
done
