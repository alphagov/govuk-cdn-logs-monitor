# Monitor 404s

Work in progress. Monitor pages on gov.uk that when previously accessed have returned html 200 response, but are now returning 404 status.

See <https://gov-uk.atlassian.net/wiki/display/FS/RFC+21%3A+Monitoring+for+404s>


# Usage

`./nightly_run.sh /src/log/directory /output/directory`
* processes the latest uncompressed log file for pages returning HTTP 2XX statuses

`./process_gz_logs.sh /src/log/directory /output/directory`
* processes all the historical logs

`./owning_app.sh "/base/path"`
* outputs the name of the application that 'owns' the html content at the specified basepath on gov.uk


# To do

1. stream 'live' cdn data and look for 404s. compare against known 200s. alert.
2. given two output files, produce the intersection: find the common basepaths

...
