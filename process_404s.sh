#!/bin/sh

read file
masterfile="${1}"

# -F handles log rotations
# -c +0 outputs the entire file (not just last ten lines)
# -c -0 watches the very end of the file
tail -F -c -0 "$file" | ruby alert_if_404_url_present.rb "$masterfile"
