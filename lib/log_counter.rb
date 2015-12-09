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
require_relative 'log_file_streamer'

class LogCounter
  FIRST_ROW_HEADING = 'Source file size'
  attr_reader :file_path
  attr_reader :counts_dir
  attr_reader :base_name
  attr_reader :work_dir
  attr_reader :daily_dir
  attr_reader :counted_dir
  attr_reader :counted_file
  attr_reader :temp_parsed_file
  attr_reader :temp_sorted_file
  attr_reader :file_size

  def initialize(file_path, counts_dir)
    @file_path = file_path
    @counts_dir = counts_dir

    @base_name = File.basename(file_path).gsub(/.gz$/, '')

    @work_dir = "#{counts_dir}/tmp"
    @daily_dir = "#{counts_dir}/daily"

    # This file is used to mark that a log has been counted.  The length of the
    # log file is written into it.
    @counted_dir = "#{counts_dir}/counted"
    @counted_file = "#{counted_dir}/counted_#{base_name}"

    @temp_parsed_file = "#{work_dir}/tmp_parsed_#{base_name}.tmp"
    @temp_sorted_file = "#{work_dir}/tmp_sorted_#{base_name}.tmp"

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

    begin
      parse_file
      sort_file
      count_file
      write_counted_file
      $logger.info "Counts written"
    ensure
      remove_temp_files
    end
  end

private

  def ensure_directories_exist
    ensure_directory_exists counts_dir
    ensure_directory_exists daily_dir
    ensure_directory_exists counted_dir
    ensure_directory_exists work_dir

    unless File.exist? "#{counted_dir}/README"
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

  def remove_temp_files
    if File.exist?(temp_parsed_file)
      File.unlink(temp_parsed_file)
    end
    if File.exist?(temp_sorted_file)
      File.unlink(temp_sorted_file)
    end
  end

  def already_counted?
    unless File.exist?(counted_file)
      return false
    end

    File.read(counted_file) == file_size.to_s
  end

  def remove_counted_file
    if File.exist?(counted_file)
      File.delete(counted_file)
    end
  end

  def write_counted_file
    File.open(counted_file, "wb") do |fd|
      fd.write(file_size.to_s)
    end
  end

  def parse_file
    $logger.info "Parsing #{file_path} - #{file_size} bytes"

    File.open(temp_parsed_file, "wb") do |out_fd|
      LogFileStreamer.open(file_path) do |stream|
        LogParser.new(stream).each do |entry|
          day = entry[:time].strftime('%Y%m%d')
          hour = entry[:time].strftime('%H')
          out_fd.write("#{day} #{hour} #{entry[:path]} #{entry[:method]} #{entry[:status]} #{entry[:cdn_backend]}\n")
        end
      end
    end
  end

  def sort_file
    $logger.info "Sorting #{temp_parsed_file}"
    unless system({"LC_ALL" => "C"}, "sort", "-o", temp_sorted_file, temp_parsed_file)
      raise "Failed to sort #{temp_parsed_file}"
    end
  end

  class ItemCounter
    attr_reader :stream
    attr_reader :daily_dir
    attr_reader :base_name

    def initialize(stream, daily_dir, base_name)
      @stream = stream
      @daily_dir = daily_dir
      @base_name = base_name

      @csv_writer = nil
      @output_file = nil
      @temp_output_file = nil
    end

    def count
      last_day = nil
      stream.each_line do |line|
        line = line.strip
        count, day, data = line.strip.split(/ /, 3)

        if day != last_day
          finish_output_file
          @csv_writer = start_output_file(day)
        end
        last_day = day

        @csv_writer << [data, count]
      end
      finish_output_file
    end

  private

    def start_output_file(day)
      output_dir = "#{daily_dir}/#{day}"
      FileUtils::mkdir_p output_dir
      @output_file = "#{output_dir}/count_#{base_name}.csv.gz"
      @temp_output_file = "#{output_dir}/tmp_#{base_name}.tmp"
      if File.exist?(@temp_output_file)
        File.delete(@temp_output_file)
      end
      $logger.info "Writing counts for #{@output_file}"
      CSV.open(@temp_output_file, "wb", encoding: 'UTF-8')
    end

    def finish_output_file
      unless @csv_writer.nil?
        @csv_writer.close
        unless system({"LC_ALL" => "C"}, "gzip", @temp_output_file)
          raise "Failed to gzip #{@temp_output_file}"
        end
        File.rename("#{@temp_output_file}.gz", @output_file)
      end
    end
  end

  def count_file
    $logger.info "Counting #{temp_sorted_file}"
    ProcessStreamer.open(["uniq", "-c", temp_sorted_file]) do |stream|
      ItemCounter.new(stream, daily_dir, base_name).count
    end
  end

  def ensure_directory_exists(dir)
    unless File.exist? dir
      Dir.mkdir dir
    end
  end
end
