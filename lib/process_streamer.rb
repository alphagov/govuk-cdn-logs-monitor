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
