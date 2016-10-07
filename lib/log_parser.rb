require 'date'
require_relative 'config_logging'

LogEntry = Struct.new(:ip, :time, :method, :path, :status, :cdn_backend)

class LogParser
  include Enumerable

  def initialize(stream)
    @stream = stream
  end

  def each(&block)
    # The cdn log line is expected to be in the following format
    # IP "-" "-" DAY, DD MMM YYYY TIME ZONE METHOD BASEPATH STATUS [CDN_BACKEND]
    #
    # The block is called with LogEntry
    @stream.each_line do |line|
      line = line.strip
      begin
        parsed = parse_line(line)
      rescue ArgumentError => e
        # Report to errbit?
        $logger.error "Invalid log line: #{e} (#{line})"
        next
      end
      block.call(parsed)
    end
  end

private

  def parse_line(line)
    pieces = line.split
    if pieces.size < 12
      raise ArgumentError.new("Less log line elements than we expect")
    end
    datetime = DateTime.parse(pieces.slice(3..8).join(' ')).new_offset
    LogEntry.new(
      pieces[0],
      datetime,
      pieces[9],
      pieces[10],
      pieces[11],
      pieces[12],
    )
  end
end
