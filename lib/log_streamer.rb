# Stream lines from a log file, handling log rotation.

require 'open3'

class ProcessStreamer
  def self.open(command)
    Open3.popen2(*command) do |_stdin, stdout, wait_thr|
      begin
        yield stdout
      rescue
        wait_thr.kill
        raise
      end
    end
  end
end

class LogTailStreamer
  def self.open(log_file)
    ProcessStreamer.open(["/usr/bin/tail", "-F", "-n", "0", log_file]) do |stream|
      yield stream
    end
  end
end

class LogFileStreamer
  def self.open(log_file, &block)
    if log_file.end_with?(".gz")
      stream_gz_file(log_file, block)
    else
      stream_uncompressed_file(log_file, block)
    end
  end

private

  def self.stream_uncompressed_file(log_file, block)
    File.open(log_file) do |stream|
      block.call(stream)
    end
  end

  def self.stream_gz_file(log_file, block)
    ProcessStreamer.open(["gunzip", "-c", log_file]) do |stream|
      block.call(stream)
    end
  end
end
