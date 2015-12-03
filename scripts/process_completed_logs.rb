# coding: utf-8
#
# Process the data in completely written log files (ie, all files other than
# the one currently being written).
#
# Requires the following environment variables to be set:
#
# GOVUK_CDN_LOG_DIR - directory containing raw CDN log files
# GOVUK_PROCESSED_DATA_DIR - directory to write proessed log data to
#
# This will process all log files of the form cdn-govuk.log* (where * is
# non-empty).  Gzipped logs are understood.
#
# Entries in the logs will first be counted, and the counts stored in `counts`
# subdirectory of the processed data dir.
#
# Then, derived lists, such as a list of the pages which were successfully
# accessed each day, and the method used to access them, will be written to the
# `successes` subdirectory.

require_relative '../lib/count_cdn_logs'
require_relative '../lib/successful_access_calculator'
require_relative '../lib/first_last_success_calculator'
require_relative '../lib/known_good_calculator'

log_dir = ENV.fetch("GOVUK_CDN_LOG_DIR", "")
processed_dir = ENV.fetch("GOVUK_PROCESSED_DATA_DIR", "")

if log_dir == ""
  raise "Must set GOVUK_CDN_LOG_DIR"
end
if processed_dir == ""
  raise "Must set GOVUK_PROCESSED_DATA_DIR"
end

CountCdnLogs.new(log_dir, processed_dir).update
SuccessfulAccessCalculator.new(processed_dir).process
FirstLastSuccessCalculator.new(processed_dir).process
KnownGoodCalculator.new(processed_dir).process
