require_relative 'process_streamer'

class LogTailStreamer
  def self.open(log_file)
    ProcessStreamer.open(["/usr/bin/tail", "-F", "-n", "0", log_file]) do |stream|
      yield stream
    end
  end
end
