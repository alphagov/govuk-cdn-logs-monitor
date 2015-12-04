# Design

This project is designed to handle the following rough constraints:

 - handle tens of millions of request logs per day.
 - run on a single machine
 - support alerting for problems as they come in.
 - process logs nightly to identify patterns in them (eg, pages which are known
   to be good).
 - the nightly processing should take only a few minutes - mustn't get
   significantly slower as more logs are added.
 - the full logs may be deleted after a relatively short period of time (eg, 1
   month), but hourly counts of the accesses to each URL should be preserved
   indefinitely.

Configuration will be passed in via environment variables: specifically:

 - `GOVUK_CDN_LOG_DIR`: the directory containing incoming logs.
 - `GOVUK_PROCESSED_DATA_DIR`: a directory for the system to write processed
   data into.  The rest of this documentation assumes this directory is set to
   "`processed`".

## Data sources

The scripts assume that all the incoming logs are placed in a single directory
(specified by the `GOVUK_CDN_LOG_DIR` environment variable) with the following
naming convention:

 - The current log is named `cdn-govuk.log`.
 - The logs for a particular day will be named matching `cdn-govuk.log*`.
 - The logs for a particular day may be compressed with gzip; if so, their name
   will end `.gz`.

### Log format

The logs are expected to be formatted as:

```
IP_ADDRESS "-" "-" DATE_TIME METHOD PATH STATUS CDN_BACKEND
```

where:

 - `IP_ADDRESS` is the IP address that the request came from.  This may be
   fully or partially redacted.
 - the second and third components are ignored, but currently always "-" in our
   logs.
 - `DATE_TIME` is the date and time that the request was made.  It is in
   [RFC2822 (section 3.3) date format](https://www.ietf.org/rfc/rfc2822.txt)
 - `METHOD` is the HTTP method used to request the resource.
 - `STATUS` is the HTTP status code returned.
 - `CDN_BACKEND` is the CDN backend used to handle the request (eg `origin`).
   Note that this component was only added recently, and is missing from many
   of our older logs.

For example:
```
1.1.1.1 "-" "-" Fri, 23 Aug 2015 10:57:28 +0100 GET /a-url 404
```

This is an annoying format to parse, since it's hard to validate.  The parser
as currently implemented will validate the date portion of this, but accept
almost any value for most of the fields.

## Output

The system produces the following output:

 - a list of "known good" URLs (more details below).
 - statsd output to track the frequency at which each HTTP status code is
   returned.
 - statsd output to track the frequency at which each CDN backend is used for
   fetching the response.
 - statsd and detailed logstash output to track any accesses to "known good"
   URLs which fail.

### Known good URLs

A URL is added to the "known good" set if:

 - it is accessed with a successful HTTP status code (either 2xx or 3xx).
 - it is accessed again with a successful HTTP status code at least 7 days
   later.
 - it contains a query string part (eg, search parameters) or a component in
   its URL indicating it is part of a smart-answer's answers, both of the days
   with accesses must have happened at least 10 times.

These constraints are designed to ensure that the very occasional items which
are published in error and quickly withdrawn do not get added to the set, and
to ensure that the very large long tail of search and smart answer URLs do not
"clog up" the known good set - keeping a reasonably small, but representative,
set of URLs.

## Nightly processing

The nightly processing of archived data is run by the
`scripts/process_completed_logs.rb` script. This places data into the
"`processed`" directory.

The processing consists of several steps:

 - counting logs.  The "current log" file is ignored for this processing, since
   it is still changing.
 - identifying successful accesses.
 - identifying successful accesses which happened at least a week apart.
 - producing a list of known good URLs.

### Counting logs

Data resulting from counting the logs is placed into `processed/raw_counts/`.
Two things are produced:

 - separate output files, in CSV format, for each day of data in each log.
   These output files are organised into separate directories based on the day
   which the log events happened on.  For example, a log file named
   `cdn-govuk.log-20150821.gz` with data from both the 21st and 22nd August
   2015 would produce two output files:

    - `processed/raw_counts/daily/20150821/count_cdn-govuk.log-20150821.csv`
    - `processed/raw_counts/daily/20150822/count_cdn-govuk.log-20150821.csv`

   Note that the directory name is the date of the entries in the output CSV
   file, and the file name is "`count_`" followed by the name of the original
   log file.  Logs do not usually contain events from only a single calendar
   day.  In particular, logs are normally rotated sometime in the early
   morning, so will contain events counting new or modified log files.  There
   may therefore be multiple count files in a single directory, and to get the
   correct counts the entries in each of these need to be summed up.

   These files contain hourly counts of accesses, for each combination of path,
   HTTP method, return status and CDN backend.  The CSV has two columns: the
   first is a string composed of the combination of these features, and the
   second is the count as an integer.  For example:

   ```
   05 /a-url GET 200 origin,1
   ```

 - details of which files have been processed, and the file sizes when they
   started being processed.  This data is recorded in files named
   `processed/raw_counts/counted/counted_<log_file_name>` (where any `.gz`
   suffix for the log file name is removed).  This data is used to ensure that
   we can re-process any log which has changed, but do not need to re-process
   all logs every day.  Removing a file from this directory will trigger the
   corresponding log to be reprocessed.

If a source log file is modified, the next nightly run will reprocess it.
However, if a source file is removed or renamed, the generated count files will
not be automatically removed - they will need to be manually removed if this is
needed to ensure that counts remain correct.  It is expected that old log files
will be removed at some point.

Note that the standard log rotation approach we use means that each log file is
compressed 1 day after being created.  This will result in the file size
changing, so the file will be re-processed.  This is unavoidable without lots
of effort, and isn't expected to be a significant problem.

### Identifying successful accesses

The next stage of processing uses the generated daily count files to produce a
list of successfully accessed URLs for each day.  This processing works by
iterating through all of the count files for a given day, adding the counts for
successful GET accesses up in memory.  URLs which either have a query string
component, or a path component of `/y/` are then removed if the count is less
than 10.

The URLs left after this processing (without the actual counts) are then
written to daily files named `processed/successes/daily/successes_DATE`, where
date is the date of the access in `YYYYMMDD` form.  This file simply holds
UTF-8 text, with one URL per line, followed by a space and the date in
`YYYYMMDD` form.

Files are only processed at this stage if the file modification time for any of
the files in the `processed/raw_counts/daily/DATE/` directory have changed, for
a given DATE (or if the directory itself has had a changed modification time).
This ensures that the `successes_DATE` files are updated only if a change has
been made to the counts for `DATE`.

### Identifying accesses separated by at least a week

All the daily lists of successful accesses are combined, by being sorted
together, and then filtered such that only the first and last access to each
URL is retained.  (If a URL is only accessed on a single day, the first and
last accesses will be represented separately, though they will be identical.)

This filtered list is written to `processed/successes/first_last`.

The sorting is done using the UNIX `sort` tool, and should thus be fairly fast
even if all the lists of successful accesses need to be combined.  However,
normally the input to the sort is simply the existing `first_last` file and any
files which have been added since the previous run; so much less data needs to
be processed.

In order to implement this, a list of files whose data has been included in the
`first_last` file is kept in `processed/successes/first_last_sources`.
This list also includes the size of the file when it was processed. If any of
the source files are removed or modified, the processing needs to be re-run
from scratch - this is detected by checking if the file size has changed.

Note - we don't use the modification time of the file to detect changes,
because when source log files are compressed the modification times of the
corresponding raw count files will be updated. However, the contents of the
corresponding raw count file won't normally change.

### Producing a list of known good URLs

Given the list of first and last accesses to each URL, the final step is
simple: each pair of access times is compared, and paths for which these are a
week or more apart are written to the `processed/output/known_good_urls`

## Monitoring

A persistent process (`scripts/monitor_logs.rb`) is run to monitor the incoming
logs.

This process uses the UNIX `tail` command to follow the log file as it changes
due to log rotation.  This could have been implemented in pure ruby, but it's
simpler to use an existing robust implementation.

The process reads the list of known good URLs from
`processed/output/known_good_urls`.  It checks the modification time of this
file every 10 seconds, and reloads the list of good URLs if this time has
changed.  This means there is no need to restart the process when the list has
been updated (or to send a signal or other notification to it).

The monitoring sends output to monitoring systems using statsd, and also
outputs messages about failures to access known good URLs to stdout (in
logstash format).
