# CDN log monitor

Monitor the CDN logs for GOV.UK to find problems with the site.

## Technical documentation

This application is a collection of shell, and Ruby, scripts that use:

- Historical and yesterday's cdn logs to calculate what pages are 'known good',
  that is, return HTTP status 2XX.
- The current log is used to monitor basepaths not being found, HTTP status
  404.

Processed logs become CSV files that contain basepath and frequency
details for that day. The CSV files are combined into a master list of known
good URLs for GOV.UK.


## Testing

Run the unit tests with rspec:

```
bundle exec rspec
```


## Dependencies

- `statsd-ruby` - ruby gem, to update 404 metrics
- `git`         - ruby gem, to have a versioned master list of good URLs


## Running

Each script accepts `-h` option that detail what the script expects.


`./process_404s.sh /cdn/log/dir /path/to/good_urls.csv`

- Streams data from the current cdn log and compares it against the known good
  pages (masterlist) on GOV.UK.
- Alerts if a 404 occurs that should not.


`./nightly_run.sh /cdn/log/dir /path/to/processed-data-dir`

- Processes the latest uncompressed log file for pages returning HTTP 2XX
  statuses.
- Outputs the list of basepaths with a 2XX status to a csv file.


`./process_gz_logs.sh /cdn/log/dir /path/to/processed-data-dir`

- Processes all the compressed historical logs into csv files.


`./accumulate.sh /path/to/processed-data-dir /path/to/good_urls.csv`

- Should be run after `nightly_run` finishes.
- Takes urls that are known to be good and adds them to the masterlist. The
  details of the algorithm used are in the ruby code that `accumulate` calls


`./owning_app.sh "/base/path"`

- Outputs the name of the application that 'owns' the html content at the
  specified basepath on gov.uk.


![CDN monitor process flow](docs/cdn-monitor-flow.png)
