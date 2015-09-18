#!/bin/sh

usage="\nExample usage:
  $(basename "$0") -h
  $(basename "$0") log-directory masterfile

where:
  -h             show this help text
  log-directory  directory where the cdn log is currently being written
  masterfile     path to the file containing the known good urls on gov.uk\n"

option="${1}"

if [ "$option" = "-h" ] || [ "$option" = "" ]; then
    echo "$usage"
    exit 0
fi

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
