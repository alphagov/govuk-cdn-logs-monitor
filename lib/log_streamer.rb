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
  def initialize(log_file, block)
    @log_file = log_file
    @block = block
  end

  def self.open(log_file, &block)
    LogFileStreamer.new(log_file, block).stream
  end

  def stream
    if @log_file.end_with?(".gz")
      stream_gz_file
    else
      stream_uncompressed_file
    end
  end

private

  def stream_uncompressed_file
    File.open(@log_file) do |stream|
      @block.call(stream)
    end
  end

  def stream_gz_file
    ProcessStreamer.open(["gunzip", "-c", @log_file]) do |stream|
      @block.call(stream)
    end
  end
end
