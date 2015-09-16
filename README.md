# govuk-cdn-logs-monitor

Monitor the CDN logs for GOV.UK to find problems with the site

## Usage

`./nightly_run.sh /src/log/directory /output/directory`
* processes the latest uncompressed log file for pages returning HTTP 2XX statuses

`./process_gz_logs.sh /src/log/directory /output/directory`
* processes all the compressed historical logs.

`./process_404s.sh /src/log/directory /path/to/masterlist.csv`
* streams data from the latest uncompressed cdn-log and compares it against the known good pages on gov.uk

`./owning_app.sh "/base/path"`
* outputs the name of the application that 'owns' the html content at the specified basepath on gov.uk.

`./accumulate.sh /src/log/directory /path/to/masterlist.csv`
* takes urls that are known to be good and adds them to the masterlist