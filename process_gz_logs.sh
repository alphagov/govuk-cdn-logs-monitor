#!/bin/sh

usage="\nExample usage:
  $(basename "$0") -h
  $(basename "$0") gz-directory csv-directory

where:
  -h             show this help text
  gz-directory   directory where the compressed logs are stored
  csv-directory  directory where the processed csv files are stored\n"

option="${1}"

if [ "$option" = "-h" ] || [ "$option" = "" ]; then
    echo "$usage"
    exit 0
fi

# accept a source and output directory to get and store the processed logs
srcdirectory="${1}"
outdirectory="${2}"

for f in $srcdirectory/*.gz; do
    # expect name to be formatted: cdn-govuk.log-YYYYMMDD.gz
    # extract YYYYMMDD part of zipped file name
    outfile=$(basename "$f" | awk '{print $4}' FS='-|\\.')

    # stop processing this file if the output already exists
    if [ -f "$outdirectory/$outfile.csv" ]; then
        echo "$outdirectory/$outfile.csv already exists"
    else
        echo "creating $outdirectory/$outfile.csv"
        gunzip "$f" -c | ruby lib/process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv"
    fi
done
