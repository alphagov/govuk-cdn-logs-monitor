#!/bin/sh

usage="\nExample usage:
  $(basename "$0") -h
  $(basename "$0") log-directory csv-directory

where:
  -h             show this help text
  log-directory  directory where the uncompressed daily log is stored
  csv-directory  directory where the processed csv files are stored\n"

option="${1}"

if [ "$option" = "-h" ] || [ "$option" = "" ]; then
    echo "$usage"
    exit 0
fi

# accept a source and output directory to get and store the processed logs
srcdirectory="${1}"
outdirectory="${2}"

# find the newest uncompressed file
infile=$(ls -1tr $srcdirectory/cdn-govuk.log-* | grep -v .gz | tail -1)

# expect name to be formatted: cdn-govuk.log-YYYYMMDD
# extract YYYYMMDD part of newest file
outfile=$(basename "$infile" | awk '{print $4}' FS='-|\\.')

echo "This process is creating $outdirectory/$outfile.csv"
ruby lib/process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv" < "$infile"
