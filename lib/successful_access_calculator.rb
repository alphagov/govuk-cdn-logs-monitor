# Process the daily count files to produce a list of successfully accessed urls
# for each day.
#
# For this calculation, a successfully accessed url is one which is:
#
# - accessed using a GET request
#
# - returned with a 2xx or 3xx status code
#
# - If there are any query parameters, successful accesses are only counted if
# they happen at least 10 times in a single day (this is to avoid rare
# searches being counted).
#
# - If there is path component which is exactly the string 'y', accesses are
# also only counted if they happen
#
# Also then maintains a file which contains the date of the first and last
# successful access to each URL

require 'fileutils'
require_relative 'config_logging'

class SuccessfulAccessCalculator
  attr_reader :counts_dir
  attr_reader :successes_dir
  attr_reader :daily_successes_dir

  def initialize(processed_dir)
    @counts_dir = "#{processed_dir}/raw_counts/daily"
    @successes_dir = "#{processed_dir}/successes"
    @daily_successes_dir = "#{successes_dir}/daily"
  end

  def process
    ensure_directories_exist
    remove_out_of_date_output
    process_counts
  end

private

  def ensure_directories_exist
    FileUtils::mkdir_p successes_dir
    FileUtils::mkdir_p daily_successes_dir
  end

  def remove_out_of_date_output
    # Remove any daily success files which don't have corresponding raw count
    # files, or for which the count files have changed.
    Dir["#{daily_successes_dir}/successes_*"].sort.each do |file_path|
      unless has_raw_count_file_and_is_up_to_date?(file_path)
        $logger.info "Removing out of date file #{file_path}"
        File.unlink(file_path)
      end
    end
  end

  def has_raw_count_file_and_is_up_to_date?(file_path)
    unless File.exist?(file_path)
      return false
    end

    day = file_path.match(/[0-9]{8}$/)
    if day.nil?
      return false
    end

    raw_count_files = Dir["#{@counts_dir}/#{day}/*.csv"] + ["#{@counts_dir}/#{day}"]
    if raw_count_files.size == 0
      return false
    end

    file_mtime = File.mtime(file_path)
    raw_count_files.each do |count_file|
      if File.mtime(count_file) > file_mtime
        return false
      end
    end

    true
  end

  def count_successes_for_day(day_dir)
    success_counts = Hash.new(0)
    Dir["#{day_dir}/count_*.csv.gz"].sort.each do |file_path|
      $logger.info "Processing counts from #{file_path}"
      ProcessStreamer.open(["gunzip", "-c", file_path]) do |stream|
        CSV.new(stream).each do |row|
          _hour, path, method, status, _cdn_origin = row[0].split(' ')
          count = row[1].to_i
          if status.match(/^2[0-9][0-9]$/) && method == 'GET'
            success_counts[path] += count
          end
        end
      end
    end
    success_counts
  end

  def process_counts
    Dir["#{counts_dir}/*"].sort.each do |day_dir|
      day = day_dir.match(/[0-9]{8}$/)
      if day.nil?
        next
      end

      success_file = "#{daily_successes_dir}/successes_#{day}"
      if has_raw_count_file_and_is_up_to_date?(success_file)
        next
      end

      success_counts = count_successes_for_day(day_dir)

      if success_counts.size == 0
        if File.exist?(success_file)
          File.unlink(success_file)
        end
      else
        temp_file = "#{daily_successes_dir}/tmp_#{day}.tmp"
        write_successes(success_counts, day, temp_file)
        File.rename(temp_file, success_file)
      end
    end
  end

  def write_successes(counts, day, dest_file)
    File.open(dest_file, "wb") do |file|
      counts.sort.each do |path, count|
        if path.include?("/y/") && count < 10
          next
        end
        if path.include?("?") && count < 10
          next
        end
        file << "#{path} #{day}\n"
      end
    end
  end
end
