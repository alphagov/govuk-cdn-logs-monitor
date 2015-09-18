#!/bin/sh

# accept a source and output directory to get and store the processed logs
srcdirectory="${1}"
outdirectory="${2}"

# find the newest file
infile=$(ls -1tr $srcdirectory/cdn-govuk.log-* | tail -1)

# expect name to be formatted: cdn-govuk.log-YYYYMMDD
# extract YYYYMMDD part of newest file
outfile=$(basename "$infile" | awk '{print $4}' FS='-|\\.')

echo "This process is creating $outdirectory/$outfile.csv"
ruby lib/process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv" < "$infile"
