# CDN log monitor

Monitor the Content Delivery Network (CDN) logs for GOV.UK to find problems
with the site.  In particular, look for cases where a URL which has been
returning a success status changes to returning an error status.

## Technical documentation

This application has two parts:

 - A process which follows incoming logs from the CDN, sending reports to
   statsd and logstash about overall traffic patterns and problems with pages
   which are known to have worked in the past.
 - A process which runs nightly to count up accesses for each hour for each
   combination of path, HTTP method, resulting HTTP status, and CDN backend
   used to serve the request.

The processing of historical logs is split into several stages, to ensure that
only the necessary additional processing is done each day.  Details of these stages are in
[the documentation](docs/design.md).

## Testing

Run the unit tests with rspec:

```
bundle exec rspec
```

## Dependencies

- `statsd-ruby` - ruby gem, to update 404 metrics

## Running

`GOVUK_PROCESSED_DATA_DIR=processed_data_directory GOVUK_CDN_LOG_DIR=log_directory bundle exec ruby ./scripts/monitor_logs.rb`

- Streams data from the current CDN log and compares it against the list of
  known good pages on GOV.UK.
- Sends statsd events about traffic levels (status codes, and CDN backends
  used).
- Sends statsd events and logstash events about accesses to pages which are in
  the list of known good urls, but which have 4xx or 5xx status codes.

`GOVUK_PROCESSED_DATA_DIR=processed_data_directory GOVUK_CDN_LOG_DIR=log_directory bundle exec ruby ./scripts/process_completed_logs.rb`

- Counts entries in all the existing logs which haven't yet been processed.
- Updates the list of known good urls.
- Designed to be run nightly.
