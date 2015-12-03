# coding: utf-8
#
# Stream lines from a log file, handling log rotation.

require 'open3'

class LogStreamer
  def initialize(log_file)
    @log_file = log_file
  end

  def with_stream(&block)
    Open3.popen2("tail -F -n 0 \"#{@log_file}\"") do |stdin, stdout, wait_thr|
      begin
        block.call(stdout)
      rescue
        wait_thr.kill
        raise
      end
    end
  end
end
