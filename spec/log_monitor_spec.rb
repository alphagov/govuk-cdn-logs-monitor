require 'spec_helper'
require 'log_monitor'

describe "Monitoring incoming logs" do
  def write_known_good(lines)
    write_lines("#{$tempdir}/output/known_good_urls", lines)
  end

  def write_log(entries, backend="origin", method="GET")
    write_lines("#{$tempdir}/log", entries.map { |url_and_status|
      %{1.1.1.1 "-" "-" Fri, 29 Aug 2015 05:57:21 GMT #{method} #{url_and_status} #{backend}}
    })
  end

  def expect_statsd_increments(monitor, items)
    statsd_sender_double = instance_double("StatsdSender")
    items.each do |item|
      expect(statsd_sender_double).to receive(:increment).once.with(item)
    end
    allow(monitor).to receive(:statsd_sender).and_return(statsd_sender_double)
  end

  it "Handles a known_good file without dates" do
    # Handle dates missing from the known_good file for a smooth transition to
    # adding them.  Can remove this support after deploy and regneration of the
    # file.
    write_known_good(["/a-url"])
    write_log(["/a-url 500"])

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.500",
      "cdn_backend.origin",
      "known_good_fail.status_500",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq(
      %{{"@fields":{"method":"GET","path":"/a-url","query_string":null,"status":500,"remote_addr":"1.1.1.1","request":"GET /a-url","cdn_backend":"origin","last_success":"2014-01-01T00:00:00+00:00"},"@tags":["known_good_fail"],"@timestamp":"2015-08-29T05:57:21+00:00","@version":"1"}\n}
    )
  end

  it "Sends output about successful accesses to known urls" do
    write_known_good(["/a-url 20150801"])
    write_log(["/a-url 200"])

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.200",
      "cdn_backend.origin",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq("")
  end

  it "Sends output about unsuccessful GET accesses to known urls" do
    write_known_good(["/a-url 20150801"])
    write_log(["/a-url 500"])

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.500",
      "cdn_backend.origin",
      "known_good_fail.status_500",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq(
      %{{"@fields":{"method":"GET","path":"/a-url","query_string":null,"status":500,"remote_addr":"1.1.1.1","request":"GET /a-url","cdn_backend":"origin","last_success":"2015-08-01T00:00:00+00:00"},"@tags":["known_good_fail"],"@timestamp":"2015-08-29T05:57:21+00:00","@version":"1"}\n}
    )
  end

  it "Doesn't send output about unsuccessful POST accesses to known urls" do
    write_known_good(["/a-url 20150801"])
    write_log(["/a-url 500"], "origin", "POST")

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.500",
      "cdn_backend.origin",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq("")
  end

  it "Sends output about successful accesses to unknown urls" do
    write_known_good(["/a-url 20150801"])
    write_log(["/an-unknown-url 200"])

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.200",
      "cdn_backend.origin",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq("")
  end

  it "Sends output about unsuccessful accesses to unknown urls" do
    write_known_good(["/a-url 20150801"])
    write_log(["/an-unknown-url 500"])

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.500",
      "cdn_backend.origin",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq("")
  end

  it "Sends the query string in logstash monitoring" do
    write_known_good(["/a-url?foo 20150801"])
    write_log(["/a-url?foo 401"])

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.401",
      "cdn_backend.origin",
      "known_good_fail.status_401",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq(
      %{{"@fields":{"method":"GET","path":"/a-url","query_string":"foo","status":401,"remote_addr":"1.1.1.1","request":"GET /a-url?foo","cdn_backend":"origin","last_success":"2015-08-01T00:00:00+00:00"},"@tags":["known_good_fail"],"@timestamp":"2015-08-29T05:57:21+00:00","@version":"1"}\n})
  end

  it "Sends output about accesses which aren't served by origin" do
    write_known_good(["/a-url 20150801"])
    write_log(["/a-url 200"], "mirror1")

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.200",
      "cdn_backend.mirror1",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq(
      %{{"@fields":{"method":"GET","path":"/a-url","query_string":null,"status":200,"remote_addr":"1.1.1.1","request":"GET /a-url","cdn_backend":"mirror1","last_success":"2015-08-01T00:00:00+00:00"},"@tags":["cdn_fallback"],"@timestamp":"2015-08-29T05:57:21+00:00","@version":"1"}\n})
  end

  it "Sends extra tags for failed accesses which worked recently" do
    write_known_good(["/a-url 20150827"])
    write_log(["/a-url 500"])

    monitor = LogMonitor.new($tempdir)
    expect_statsd_increments(monitor, [
      "status.500",
      "cdn_backend.origin",
      "known_good_fail.status_500",
      "recent_known_good_fail.status_500",
    ])

    record_stderr
    record_stdout
    monitor.monitor(File.open("#{$tempdir}/log"))

    expect(recorded_stderr).to match("Working with 1 known good urls")
    expect(recorded_stdout).to eq(
      %{{"@fields":{"method":"GET","path":"/a-url","query_string":null,"status":500,"remote_addr":"1.1.1.1","request":"GET /a-url","cdn_backend":"origin","last_success":"2015-08-27T00:00:00+00:00"},"@tags":["known_good_fail","recent_known_good_fail"],"@timestamp":"2015-08-29T05:57:21+00:00","@version":"1"}\n}
    )
  end
end
