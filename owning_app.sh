#!/bin/sh

usage="\nExample usage:
  $(basename "$0") -h
  $(basename "$0") basepath

where:
  -h        show this help text
  basepath  part of the gov.uk url, eg: /browse, /government/announcements\n"

option="${1}"

if [ "$option" = "-h" ]; then
    echo "$usage"
    exit 0
else
    basepath="$option"
fi

# only works for html pages
content=$(curl -s "https://www.gov.uk$basepath")
echo "$content" | sed -n -e 's/^.*govuk:rendering-application\" content=\"\([^\"]*\).*/\1/p'
