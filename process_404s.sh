#!/bin/sh

srcdirectory="${1}"
masterfile="${2}"

srcfile=$(ls -1tr "$srcdirectory" | tail -1)

# -F handles log rotations
# -c +0 outputs the entire file (not just last ten lines)
# -c -0 watches the very end of the file
tail -F -c -0 "$srcdirectory/$srcfile" | ruby alert_if_404_url_present.rb "$masterfile"
