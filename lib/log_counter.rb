# Count hits to each url in a log file.
#
# Writes the output to file named according to the date and hour of the hits,
# together with the name of the source log file, in the supplied output
# directory.
#
# Counts the unique combinations of path, HTTP method, HTTP status, time to
# the resolution of an hour, and CDN backend.

require 'csv'
require_relative 'log_counter'
require_relative 'log_parser'

class LogCounter
  FIRST_ROW_HEADING = 'Source file size'
  attr_reader :file_path
  attr_reader :counts_dir
  attr_reader :base_name
  attr_reader :daily_dir
  attr_reader :counted_dir
  attr_reader :counted_file
  attr_reader :file_size

  def initialize(file_path, counts_dir)
    @file_path = file_path
    @counts_dir = counts_dir

    @base_name = File.basename(file_path).gsub(/.gz$/, '')

    @daily_dir = "#{counts_dir}/daily"

    # This file is used to mark that a log has been counted.  The length of the
    # log file is written into it.
    @counted_dir = "#{counts_dir}/counted"
    @counted_file = "#{counted_dir}/counted_#{base_name}"

    # Fetch this explicitly at the start.  This ensures that if the file is
    # still being written to, the size stored in the output file will differ
    # from the size of the log file, so a future run will re-process this file.
    @file_size = File.size(file_path)

    ensure_directories_exist
  end

  def ensure_counted
    if already_counted?
      return
    end

    counts_by_day = process_file
    write_counts(counts_by_day)
    write_counted_file
    $logger.info "Counts written"
  end

private

  def ensure_directories_exist
    ensure_directory_exists counts_dir
    ensure_directory_exists daily_dir
    ensure_directory_exists counted_dir

    unless File.exists? "#{counted_dir}/README"
      File.open("#{counted_dir}/README", "wb") do |file|
        file << %{Counted files directory

This directory contains marker files indicating which source log files have
been processed.  Each file has a name corresponding to a log file which was
present in the source log directory.  The file contains the size of the log
file at the time it was processed, as a decimal string.  Logs will be
re-processed if their sizes do not match the stored value.

To trigger re-processing of a particular log file, remove the corresponding
file from this directory.
}
      end
    end
  end

  def already_counted?
    unless File.exists?(counted_file)
      return false
    end

    File.read(counted_file) == file_size.to_s
  end

  def remove_counted_file
    if File.exists?(counted_file)
      File.delete(counted_file)
    end
  end

  def write_counted_file
    File.open(counted_file, "wb") do |fd|
      fd.write(file_size.to_s)
    end
  end

  def process_file
    $logger.info "Counting #{file_path} - #{file_size} bytes"

    counts_by_day = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    parser = LogParser.open(file_path)
    parser.each do |entry|
      day = entry[:time].strftime('%Y%m%d')
      hour = entry[:time].strftime('%H')
      key = "#{hour} #{entry[:path]} #{entry[:method]} #{entry[:status]} #{entry[:cdn_backend]}"
      counts_by_day[day][key] += 1
    end

    counts_by_day
  end

  def write_counts(counts_by_day)
    $logger.info "Writing counts"

    counts_by_day.sort.each do |day, counts|
      output_dir = "#{daily_dir}/#{day}"
      ensure_directory_exists(output_dir)

      # Write to a temporary file, and then rename, to avoid partially written
      # files ever matching the pattern "count_*", and to ensure that failures
      # will be retried.
      temp_file = "#{output_dir}/tmp_#{base_name}.tmp"
      write_counts_for_day(day, counts, temp_file)

      output_file = "#{output_dir}/count_#{base_name}.csv"
      File.rename(temp_file, output_file)
    end
  end

  def ensure_directory_exists(dir)
    unless File.exists? dir
      Dir.mkdir dir
    end
  end

  def write_counts_for_day(day, counts, dest_file)
    if File.exists?(dest_file)
      File.delete(dest_file)
    end

    CSV.open(dest_file, 'wb', encoding: 'UTF-8') do |csv|
      counts.sort.each do |key, count|
        csv << [key, count]
      end
    end
  end

  def filter_counts(counts)
    counts.reject { |key, count|
      path = key.split[3]
      # Reject some paths which might contain personal information, if they've
      # not been accessed frequently:
      #  - smart answer paths include a /y/ section before the answers to
      #  questions.
      #  - things like searches contain query strings
      #
      count < 10 && (
        path.include?("/y/") || path.include("?")
      )
    }
  end
end
