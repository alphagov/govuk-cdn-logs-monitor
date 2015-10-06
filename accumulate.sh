#!/bin/sh

usage="
Example usage:
  $(basename "$0") -h
  $(basename "$0") [processed-data [good-urls]]

where:
  -h              show this help text
  processed-data  path to the directory where processed data files are stored
                  defaults to $GOVUK_PROCESSED_DATA_DIR environment variable
  good-urls       path to the file containing the known good urls on GOV.UK
                  defaults to $GOVUK_GOOD_URLS_FILE environment variable
"

option="${1}"

if [ "$option" = "-h" ]; then
    echo "$usage"
    exit 0
fi

processeddata="${1}"
if [ -z "${processeddata}" ]; then
    processeddata="${GOVUK_PROCESSED_DATA_DIR}"
fi
if [ ! -e "${processeddata}" ]; then
    echo "${processeddata} not found"
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

bundle exec ruby lib/accumulate_into_master.rb "${processeddata}" "${good_urls}"
