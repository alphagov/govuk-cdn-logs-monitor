require 'spec_helper'
require 'log_counter'

describe "Count logfiles" do
  def count_log(logfile)
    counts_dir = "#{$tempdir}/counts"
    counter = LogCounter.new(logfile, counts_dir)
    record_stderr
    counter.ensure_counted
    [counts_dir, recorded_stderr]
  end

  it "Counts a sample log file" do
    logfile = "#{$tempdir}/log"
    write_lines(logfile, [
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:27 GMT GET /a-url 200 origin',
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:28 GMT GET /another-url 200 origin',
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:29 GMT GET /a-url 200 origin',
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 06:57:29 GMT GET /a-url 200 origin',
      '1.1.1.1 "-" "-" Fri, 22 Aug 2015 05:57:27 GMT GET /a-url 200 origin',
    ])

    counts_dir, _stderr = count_log(logfile)
    expect(read_lines("#{counts_dir}/daily/20150821/count_log.csv.gz")).to eq([
      "05 /a-url GET 200 origin,2",
      "05 /another-url GET 200 origin,1",
      "06 /a-url GET 200 origin,1",
    ])
    expect(read_lines("#{counts_dir}/daily/20150822/count_log.csv.gz")).to eq([
      "05 /a-url GET 200 origin,1",
    ])
  end

  it "knows when recount is not needed" do
    logfile = "#{$tempdir}/log"
    write_lines(logfile, [
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:27 GMT GET /a-url 200 origin',
    ])
    counts_dir, stderr = count_log(logfile)
    expect(stderr).to match "Counting"

    counter = LogCounter.new(logfile, counts_dir)
    expect(counter.send(:already_counted?)).to be true

    _counts_dir, stderr = count_log(logfile)
    expect(stderr).to eq ""
  end

  it "knows to recount when file has grown" do
    logfile = "#{$tempdir}/log"
    write_lines(logfile, [
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:27 GMT GET /a-url 200 origin',
    ])
    counts_dir, stderr = count_log(logfile)
    expect(stderr).to match "Counting"

    write_lines(logfile, [
      '1.1.1.1 "-" "-" Fri, 21 Aug 2015 05:57:28 GMT GET /a-url 200 origin',
    ])

    counter = LogCounter.new(logfile, counts_dir)
    expect(counter.send(:already_counted?)).to be false
  end
end
