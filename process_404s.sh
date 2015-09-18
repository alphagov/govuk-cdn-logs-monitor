#!/bin/sh

srcdirectory="${1}"
masterfile="${2}"

srcfile=$(find "$srcdirectory/cdn-govuk.log")

# -F handles log rotations
# -c +0 outputs the entire file (not just last ten lines)
# -c -0 watches the very end of the file
if [ $? -eq 0 ]; then
    tail -F -c -0 "$srcfile" | ruby lib/alert_if_404_url_present.rb "$masterfile"
else
    echo "$srcdirectory/cdn-govuk.log not found"
fi
