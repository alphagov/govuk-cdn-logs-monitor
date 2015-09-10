#!/bin/sh

# experiment: only works for html pages
read basepath
content=$(curl -s "https://www.gov.uk$basepath")
echo "$content" | sed -n -e 's/^.*govuk:rendering-application\" content=\"\([^\"]*\).*/\1/p'
