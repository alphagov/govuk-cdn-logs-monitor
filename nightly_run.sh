#!/bin/sh

# accept a source and output directory to get and store the processed logs
srcdirectory="${1}"
outdirectory="${2}"

# find the newest file
infile=$(ls "$srcdirectory" | sort -n -t _ -k 2 | tail -1)

# expect name to be formatted: cdn-govuk.log-YYYYMMDD.gz
# extract YYYYMMDD part of newest file
outfile=$(echo "$infile" | awk '{print $4}' FS='-|\\.')

echo "This process is creating $outdirectory/$outfile.csv"
ruby process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv" < "$srcdirectory/$infile"
