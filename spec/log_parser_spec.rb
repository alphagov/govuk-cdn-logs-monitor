require 'spec_helper'
require 'log_parser'

describe "Parse logfiles" do
  def parse_log_line(logline)
    logfile = "#{$tempdir}/log"
    write_lines(logfile, [logline])
    LogFileStreamer.open(logfile) { |stream| LogParser.new(stream).to_a }
  end

  it "Parses a valid log line" do
    entries = parse_log_line(
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:27 GMT GET /a-url 301 origin',
    )

    expect(entries.size).to eq(1)
    expect(entries[0].ip).to eq('1.1.1.1')
    expect(entries[0].time).to eq(DateTime.iso8601('2015-08-21T05:57:27'))
    expect(entries[0].method).to eq('GET')
    expect(entries[0].path).to eq('/a-url')
    expect(entries[0].status).to eq('301')
    expect(entries[0].cdn_backend).to eq('origin')
  end

  it "Parses a log line with a non-zero timezone" do
    entries = parse_log_line(
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 10:57:28 +0100 GET /a-url 301 stale'
    )
    expect(entries.size).to eq(1)
    expect(entries[0].time).to eq(DateTime.iso8601('2015-08-21T09:57:28'))
  end

  it "Parses a log line without a CDN backend" do
    entries = parse_log_line(
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 10:57:28 +0000 GET /a-url 301',
    )

    expect(entries.size).to eq(1)
    expect(entries[0].path).to eq('/a-url')
    expect(entries[0].status).to eq('301')
    expect(entries[0].cdn_backend).to be_nil
  end

  it "Parses a gzipped file" do
    logfile = "#{$tempdir}/log"
    write_lines(logfile, [
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:27 GMT GET /a-url 301 origin',
    ])

    # Compress the file with the system gzip, to ensure the internal ruby's
    # zlib implementation we use handles that format correctly.
    `gzip "#{logfile}"`

    entries = LogFileStreamer.open("#{logfile}.gz") { |stream| LogParser.new(stream).to_a }
    expect(entries.size).to eq(1)
    expect(entries[0].ip).to eq('1.1.1.1')
  end

  it "Logs an error to stderr for invalid dates in log lines" do
    record_stderr
    entries = parse_log_line(
      '1.1.1.1 "-" "-" Fri, 32 Aug 2015 10:57:28 +0000 GET /a-url 301',
    )

    expect(entries.size).to eq(0)
    expect(recorded_stderr).to match("Invalid log line: invalid date")
  end

  it "Logs an error to stderr for invalid log lines" do
    record_stderr
    entries = parse_log_line(
      '1.1.1.1 "-" "-" 32 Aug 2015 10:57:28 +0000 GET /a-url 301',
    )

    expect(entries.size).to eq(0)
    expect(recorded_stderr).to match("Invalid log line: Less log line elements than we expect")
  end
end
