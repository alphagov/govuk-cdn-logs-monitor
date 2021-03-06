require 'fileutils'
require 'rspec'
require 'tmpdir'

RSpec.configure do |config|
  config.before(:each) do
    $tempdir = Dir.mktmpdir
  end

  config.after(:each) do
    FileUtils.rmtree($tempdir)
    stop_recording_stdout
    stop_recording_stderr
  end
end

def record_stdout
  $redirected_stdout_file = "#{$tempdir}/out.txt"
  $original_stdout = $stdout.to_io.dup
  $stdout.reopen($redirected_stdout_file, 'w')
end

def stop_recording_stdout
  unless $original_stdout.nil?
    $stdout.reopen($original_stdout)
    $original_stdout = nil
  end
end

def recorded_stdout
  stop_recording_stdout
  File.read($redirected_stdout_file)
end

def record_stderr
  $redirected_stderr_file = "#{$tempdir}/err.txt"
  $original_stderr = $stderr.to_io.dup
  $stderr.reopen($redirected_stderr_file, 'w')
end

def stop_recording_stderr
  unless $original_stderr.nil?
    $stderr.reopen($original_stderr)
    $original_stderr = nil
  end
end

def recorded_stderr
  stop_recording_stderr
  File.read($redirected_stderr_file)
end

def write_lines(file_name, lines)
  dir = File.dirname(file_name)
  unless File.exist?(dir)
    FileUtils::mkdir_p dir
  end
  if file_name.end_with? '.gz'
    unzipped_name = file_name.sub(/.gz$/, '')
  else
    unzipped_name = file_name
  end
  File.open(unzipped_name, "ab") do |fd|
    lines.each do |line|
      fd.write line
      fd.write "\n"
    end
  end
  if file_name.end_with? '.gz'
    `gzip "#{unzipped_name}"`
  end
end

def read_lines(file_name)
  if file_name.end_with?('.gz')
    `gunzip -c "#{file_name}"`.split("\n").map(&:rstrip)
  else
    File.readlines(file_name).map(&:rstrip)
  end
end
