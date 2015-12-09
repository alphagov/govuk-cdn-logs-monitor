require 'open3'

class ProcessStreamer
  def self.open(command)
    Open3.popen2({"LC_ALL" => "C"}, *command) do |_stdin, stdout, wait_thr|
      begin
        result = yield stdout
        exit_status = wait_thr.value
        unless exit_status
          raise "Command #{command} failed with exit status #{exit_status}"
        end
        result
      rescue
        wait_thr.kill
        raise
      end
    end
  end
end
