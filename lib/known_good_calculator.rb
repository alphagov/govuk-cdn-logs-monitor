# Process the first-last success file to produce a list of known good urls.
#
# A url is marked as being a known good url if it is accessed successfully at
# two times a week or more apart.  This separation is required to ensure that
# things which are accidentally published and then quickly removed aren't added
# to the list.

require_relative 'config_logging'

class KnownGoodCalculator
  attr_reader :output_dir
  attr_reader :first_last_file
  attr_reader :known_good_urls_file

  REQUIRED_SEPARATION_DAYS = 7

  def initialize(processed_dir)
    successes_dir = "#{processed_dir}/successes"
    @output_dir = "#{processed_dir}/output"
    @first_last_file = "#{successes_dir}/first_last"
    @known_good_urls_file = "#{output_dir}/known_good_urls"
  end

  def process
    ensure_directories_exist
    unless already_up_to_date
      calculate_known_good_urls
    end
  end

private

  def ensure_directories_exist
    unless File.exists? output_dir
      Dir.mkdir(output_dir)
    end
  end

  def already_up_to_date
    (
      File.exists?(known_good_urls_file) &&
      File.mtime(known_good_urls_file) >= File.mtime(first_last_file)
    )
  end

  def calculate_known_good_urls
    $logger.info "Calculating known good urls"
    temp_file = "#{known_good_urls_file}.tmp"
    File.open(temp_file, "wb") do |outfd|
      File.open(first_last_file, "rb") do |fd|
        fd.each_line.each_slice(2) do |line1, line2|
          path, first_day = line1.strip.split(" ", 2)
          last_path, last_day = line2.strip.split(" ", 2)
          if path != last_path
            raise "Unmatched lines in #{first_last_file}"
          end
          first_date = Date.iso8601(first_day)
          last_date = Date.iso8601(last_day)
          elapsed_days = (last_date - first_date).to_i
          if elapsed_days >= REQUIRED_SEPARATION_DAYS
            outfd.write "#{path}\n"
          end
        end
      end
    end

    File.rename(temp_file, known_good_urls_file)
  end
end
