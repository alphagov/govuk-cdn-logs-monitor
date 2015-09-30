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

srcfile="${1}"
if [ -z "${srcfile}" ]; then
    srcfile="${GOVUK_CDN_LOG_FILE}"
fi

good_urls="${2}"
if [ -z "${good_urls}" ]; then
    good_urls="${GOVUK_GOOD_URLS_FILE}"
fi

# -F handles log rotations
# -c +0 outputs the entire file (not just last ten lines)
# -c -0 watches the very end of the file
if [ -e "${srcfile}" ]; then
    tail -F -c -0 "${srcfile}" | bundle exec ruby lib/alert_if_404_url_present.rb "${good_urls}"
else
    echo "${srcfile} not found"
fi
