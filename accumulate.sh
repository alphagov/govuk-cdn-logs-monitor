#!/bin/sh

usage="\nExample usage:
  $(basename "$0") -h
  $(basename "$0") csv-directory masterfile

where:
  -h             show this help text
  csv-directory  directory where the processed csv files are stored
  masterfile     path to the file containing the known good urls on gov.uk\n"

option="${1}"

if [ "$option" = "-h" ] || [ "$option" = "" ]; then
    echo "$usage"
    exit 0
fi

srcdirectory="${1}"
masterfile="${2}"

ruby lib/accumulate_into_master.rb "$srcdirectory" "$masterfile"
