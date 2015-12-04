# Count hits to each url in the log files
#
# Ensures that there are counts in the `<processed_dir>/raw_counts/` tree for
# all log files which exist.
#
# If log files are removed, the counts are retained, so that we can archive the
# logs but still do historical analysis of trends.

require_relative 'config_logging'
require_relative 'log_counter'

class CountCdnLogs
  def initialize(log_dir, processed_dir)
    @log_dir = log_dir
    @processed_dir = processed_dir
    @counts_dir = "#{processed_dir}/raw_counts"
  end

  def update
    files = completed_log_files
    $logger.info "Checking #{completed_log_files.count} log files"
    files.each do |file_path|
      LogCounter.new(file_path, @counts_dir).ensure_counted
    end
  end

private

  def completed_log_files
    Dir["#{@log_dir}/cdn-govuk.log*"].reject { |name|
      File.basename(name) == 'cdn-govuk.log'
    }.sort
  end
end
