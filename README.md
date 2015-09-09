# Monitor 404s

Work in progress. Monitor pages on gov.uk that when previously accessed have returned html 200 response, but are now returning 404 status.

See <https://gov-uk.atlassian.net/wiki/display/FS/RFC+21%3A+Monitoring+for+404s>


# To do

1. nightly script that accepts the destination folder for processed log files
2. script that processes all the zipped (archived) files
3. given two output files, produce the intersection: find the common basepaths
...