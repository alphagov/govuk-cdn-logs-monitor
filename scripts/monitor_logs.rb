# Monitor events which happen in the current log file
#
# Requires the following environment variables to be set:
#
# GOVUK_CDN_LOG_DIR - directory containing raw CDN log files
# GOVUK_PROCESSED_DATA_DIR - directory to write proessed log data to

require_relative '../lib/log_monitor'
require_relative '../lib/log_tail_streamer'

log_dir = ENV.fetch("GOVUK_CDN_LOG_DIR", "")
processed_dir = ENV.fetch("GOVUK_PROCESSED_DATA_DIR", "")

if log_dir == ""
  raise "Must set GOVUK_CDN_LOG_DIR"
end
if processed_dir == ""
  raise "Must set GOVUK_PROCESSED_DATA_DIR"
end

log_file = "#{log_dir}/cdn-govuk.log"
monitor = LogMonitor.new(processed_dir)
LogTailStreamer.open(log_file) do |stream|
  monitor.monitor(stream)
end
