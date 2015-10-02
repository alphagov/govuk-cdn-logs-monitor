#!/bin/sh

usage="
Example usage:
  $(basename "$0") -h
  $(basename "$0") [log-file [good-urls]]

where:
  -h         show this help text
  log-file   path to the file where the cdn log is currently being written
  good-urls  path to the file containing the known good urls on GOV.UK
"

option="${1}"

if [ "$option" = "-h" ]; then
    echo "$usage"
    exit 0
fi

logfile="${1}"
if [ -z "${logfile}" ]; then
    logfile="${GOVUK_CDN_LOG_FILE}"
fi
if [ ! -e "${logfile}" ]; then
    echo "${logfile} not found"
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

tail -F -c -0 "${logfile}" | bundle exec ruby lib/alert_if_404_url_present.rb "${good_urls}"
