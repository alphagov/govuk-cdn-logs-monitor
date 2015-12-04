# Process the list of successfully accessed urls for each day to produce a
# single file containing the dates when each such url was first and last
# accessed.

require 'open3'
require_relative 'config_logging'

class FirstLastSuccessCalculator
  attr_reader :daily_successes_dir
  attr_reader :first_last_file
  attr_reader :first_last_sources_file

  def initialize(processed_dir)
    successes_dir = "#{processed_dir}/successes"
    @daily_successes_dir = "#{successes_dir}/daily"
    @first_last_file = "#{successes_dir}/first_last"
    @first_last_sources_file = "#{successes_dir}/first_last_sources"
  end

  def process
    remove_out_of_date_output
    update_first_last
  end

private

  def current_daily_files_and_sizes
    @current_daily_files_and_sizes ||=
    Dir["#{daily_successes_dir}/successes_*"].each_with_object({}) { |path, result|
      result[path] = File.size(path)
    }
  end

  def stored_daily_files_and_sizes
    @stored_daily_files_and_sizes ||=
    if File.exists? first_last_sources_file
      File.readlines(first_last_sources_file).each_with_object({}) { |line, result|
        path, stored_size = line.strip.split(/ /, 2)
        result[path] = stored_size.to_i
      }
    else
      {}
    end
  end

  def remove_out_of_date_output
    if source_files_have_changed_or_gone
      remove_generated_files
    end
  end

  def source_files_have_changed_or_gone
    stored_daily_files_and_sizes.each do |path, stored_size|
      current_size = current_daily_files_and_sizes[path]
      if current_size.nil? || current_size != stored_size.to_i
        return true
      end
    end

    false
  end

  def remove_generated_files
    if File.exists? first_last_file
      $logger.info "Removing #{first_last_file}"
      File.unlink first_last_file
    end

    if File.exists? first_last_sources_file
      $logger.info "Removing #{first_last_sources_file}"
      File.unlink first_last_sources_file
    end
    @stored_daily_files_and_sizes = {}
  end

  def write_sources_used(dest_file)
    File.open(dest_file, "wb") do |output_fd|
      current_daily_files_and_sizes.sort.each do |daily_file, file_size|
        output_fd << "#{daily_file} #{file_size}\n"
      end
    end
  end

  def update_first_last
    # Maintain "first_last_file" with a line for the first and last successful
    # access of each path. Do this by finding any daily success files which
    # haven't been processed already (ie, aren't already in the
    # first_last_sources_file), sorting them together with the first_last_file,
    # and keeping the first and last entries for each url.

    source_files = (
      current_daily_files_and_sizes.keys - stored_daily_files_and_sizes.keys
    ).sort

    if source_files.size == 0
      $logger.info "No updated daily files"
      return
    end
    if File.exists?(first_last_file)
      source_files << first_last_file
    end

    $logger.info "Calculating first and last access times from:\n - #{source_files.join "\n - "}"
    temp_first_last_file = "#{first_last_file}.tmp"
    File.open(temp_first_last_file, "wb") do |output_file|
      Open3.popen2("sort --files0-from=-") do |stdin, stdout, wait_thr|
        stdin.write(source_files.join("\0"))
        stdin.close

        last_path = nil
        last_line = nil
        stdout.each_line do |line|
          path, _ = line.split(" ")
          if path != last_path
            unless last_line.nil?
              output_file.write(last_line)
            end
            output_file.write(line)
          end

          last_path = path
          last_line = line
        end
        unless last_line.nil?
          output_file.write(last_line)
        end

        exit_status = wait_thr.value
        unless exit_status.success?
          raise "Sort failed, exit status #{exit_status.exitstatus}"
        end
      end
    end

    temp_first_last_sources_file = "#{first_last_sources_file}.tmp"
    write_sources_used(temp_first_last_sources_file)

    File.rename(temp_first_last_file, first_last_file)
    File.rename(temp_first_last_sources_file, first_last_sources_file)
  end
end
