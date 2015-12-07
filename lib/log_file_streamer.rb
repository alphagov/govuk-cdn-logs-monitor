require_relative 'process_streamer'

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
