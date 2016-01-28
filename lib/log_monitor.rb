# Monitor the current log file, recording interesting events to statsd and
# logstash.
#
# Handles the log file being rotated, and data files (such as the list of known
# good urls) being updated.
#
# This records events to statsd about which CDN backend was used to serve
# requests, and about instances of errors which happen on known-good

require 'set'
require_relative 'config_logging'
require_relative 'log_parser'
require_relative 'logstash_sender'
require_relative 'statsd_sender'

class LogMonitor
  # Only check the calculated data files every 10 seconds
  FILE_CHECK_INTERVAL_SECONDS = 10

  def initialize(processed_dir)
    @known_good_urls_file = "#{processed_dir}/output/known_good_urls"
    @statsd_sender = StatsdSender.new
    @logstash_sender = LogstashSender.new
  end

  def monitor(stream)
    parser = LogParser.new(stream)
    parser.each do |log_entry|
      update_known_good_urls if recheck_due
      handle_entry(log_entry)
    end
  end

private
  attr_reader :statsd_sender, :logstash_sender, :known_good_urls

  def handle_entry(log_entry)
    log_access(log_entry)
    check_fails(log_entry)
  end

  def log_access(log_entry)
    statsd_sender.increment("status.#{log_entry.status}")

    if !(log_entry.cdn_backend.nil?) && log_entry.cdn_backend != ''
      statsd_sender.increment("cdn_backend.#{log_entry.cdn_backend}")
    end
  end

  def check_fails(log_entry)
    logstash_tags = []
    last_success = nil

    if log_entry.method == "GET"
      # Our list of known good urls is only for GET requests, so ignore any
      # non-GET requests for this bit of monitoring.
      last_success = last_success_date(log_entry)

      if status_code_is_failure?(log_entry) && last_success != nil
        statsd_sender.increment("known_good_fail.status_#{log_entry.status}")
        logstash_tags << "known_good_fail"

        if (log_entry.time - last_success).to_i < 7
          statsd_sender.increment("recent_known_good_fail.status_#{log_entry.status}")
          logstash_tags << "recent_known_good_fail"
        end
      end
    end

    logstash_tags << "cdn_fallback" if cdn_fall_back?(log_entry)

    logstash_sender.log(log_entry, logstash_tags, last_success) unless logstash_tags.empty?
  end

  def last_success_date(log_entry)
    date = known_good_urls[log_entry.path]
    unless date.nil?
      DateTime.iso8601(date)
    end
  end

  def status_code_is_failure?(log_entry)
    log_entry.status !~ /^[123][0-9][0-9]$/
  end

  def cdn_fall_back?(log_entry)
    ! [nil, "", "origin"].include?(log_entry.cdn_backend)
  end

  def recheck_due
    if (
      @last_checked_files.nil? ||
      Time.now - @last_checked_files < FILE_CHECK_INTERVAL_SECONDS
    )
      @last_checked_files = Time.now
      true
    else
      false
    end
  end

  def update_known_good_urls
    mtime = File.mtime(@known_good_urls_file)
    unless mtime == @known_good_urls_mtime
      @known_good_urls = read_known_good_urls
      @known_good_urls_mtime = mtime
      $logger.info "Working with #{known_good_urls.size} known good urls"
    end
  end

  def read_known_good_urls
    $logger.info "Reading set of known good urls"
    urls = {}
    File.open(@known_good_urls_file) do |fd|
      fd.each_line do |line|
        url, _, last_success = line.strip.rpartition(' ')
        if url == ''
          # This case is here to keep the monitor running with the old-format
          # "known_urls" file which didn't contain a date.
          url = last_success
          last_success = '20140101'
        end
        urls[url] = last_success
      end
    end
    urls
  end
end
