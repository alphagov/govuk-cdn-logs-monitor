#!/bin/sh

usage="
Example usage:
  $(basename "$0") -h
  $(basename "$0") [csv-directory [good-urls]]

where:
  -h             show this help text
  csv-directory  path to the directory where processed csv files are stored
  good-urls      path to the file containing the known good urls on GOV.UK
"

option="${1}"

if [ "$option" = "-h" ]; then
    echo "$usage"
    exit 0
fi

csvdir="${1}"
if [ -z "${csvdir}" ]; then
    csvdir="${GOVUK_CDN_CSV_DIR}"
fi
if [ ! -e "${csvdir}" ]; then
    echo "${csvdir} not found"
    exit 1
fi

good_urls="${2}"
if [ -z "${good_urls}" ]; then
    good_urls="${GOVUK_GOOD_URLS_FILE}"
fi
if [ ! -e "${good_urls}" ]; then
    echo "${good_urls} not found"
    exit 1
fi

bundle exec ruby lib/accumulate_into_master.rb "${csvdir}" "${good_urls}"
