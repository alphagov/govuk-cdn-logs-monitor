require './lib/config'

RSpec.configure do |config|
  config.before(:each) do
    `rm -f /tmp/*.csv`

    $original_stdin = $stdin.to_io.dup
    $original_stdout = $stdout.to_io.dup
    $original_stderr = $stderr.to_io.dup

    $stdout.reopen('/tmp/out.txt','w')
    $stderr.reopen('/tmp/err.txt','w')
  end

  config.after(:each) do
    $stdin.reopen($original_stdin)
    $stdout.reopen($original_stdout)
    $stderr.reopen($original_stderr)
  end
end

def file_contents(filename)
  contents = ""
  File.open(filename,'r') do |f|
    contents = f.read
  end
  contents
end
