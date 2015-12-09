require 'spec_helper'
require 'successful_access_calculator'

describe "Finding successful accesses" do
  def counts_dir
    "#{$tempdir}/raw_counts/daily"
  end

  def daily_successes_dir
    "#{$tempdir}/successes/daily"
  end

  def default_day
    "20150821"
  end

  it "Finds the 2xx accesses" do
    write_lines("#{counts_dir}/#{default_day}/count_1.csv.gz", [
      '05 /a-200-url GET 200 origin,1',
      '05 /a-201-url GET 201 origin,1',
      '05 /a-301-url GET 301 origin,1',
      '05 /a-400-url GET 400 origin,1',
      '05 /a-500-url GET 500 origin,1',
    ])

    record_stderr
    SuccessfulAccessCalculator.new($tempdir).process

    expect(recorded_stderr).to match("Processing counts from .*/#{default_day}/count_1\.csv")
    expect(read_lines("#{daily_successes_dir}/successes_#{default_day}")).to eq([
      "/a-200-url #{default_day}",
      "/a-201-url #{default_day}",
    ])
  end


  it "Filters out smartanswers which visited fewer than 10 times in a day" do
    write_lines("#{counts_dir}/#{default_day}/count_1.csv.gz", [
      '05 /smartanswer/y/count-9 GET 200 origin,9',
      '05 /smartanswer/y/count-10 GET 200 origin,10',
    ])

    record_stderr
    SuccessfulAccessCalculator.new($tempdir).process

    expect(recorded_stderr).to match("Processing counts from .*/#{default_day}/count_1\.csv")
    expect(read_lines("#{daily_successes_dir}/successes_#{default_day}")).to eq([
      "/smartanswer/y/count-10 #{default_day}",
    ])
  end

  it "Filters out urls with query strings visited fewer than 10 times in a day" do
    write_lines("#{counts_dir}/#{default_day}/count_1.csv.gz", [
      '05 /search?q=unusual GET 200 origin,9',
      '05 /search?q=tax GET 200 origin,10',
    ])

    record_stderr
    SuccessfulAccessCalculator.new($tempdir).process

    expect(recorded_stderr).to match("Processing counts from .*/#{default_day}/count_1\.csv")
    expect(read_lines("#{daily_successes_dir}/successes_#{default_day}")).to eq([
      "/search?q=tax #{default_day}",
    ])
  end

  it "Adds up counts from separate hours in a day" do
    write_lines("#{counts_dir}/#{default_day}/count_1.csv.gz", [
      '05 /smartanswer/y/count-5 GET 200 origin,5',
      '06 /smartanswer/y/count-5 GET 200 origin,5',
    ])

    record_stderr
    day_dir = "#{counts_dir}/#{default_day}"
    counts = SuccessfulAccessCalculator.new($tempdir).send(:count_successes_for_day, day_dir)

    expect(recorded_stderr).to match("Processing counts from .*/#{default_day}/count_1\.csv")
    expect(counts).to eq({
      "/smartanswer/y/count-5" => 10,
    })
  end

  it "Adds up counts from separate count files in a day" do
    write_lines("#{counts_dir}/#{default_day}/count_1.csv.gz", [
      '05 /smartanswer/y/count GET 200 origin,5',
    ])
    write_lines("#{counts_dir}/#{default_day}/count_2.csv.gz", [
      '06 /smartanswer/y/count GET 200 origin,7',
    ])

    record_stderr
    day_dir = "#{counts_dir}/#{default_day}"
    counts = SuccessfulAccessCalculator.new($tempdir).send(:count_successes_for_day, day_dir)

    expect(recorded_stderr).to match("Processing counts from .*/#{default_day}/count_1\.csv")
    expect(recorded_stderr).to match("Processing counts from .*/#{default_day}/count_2\.csv")
    expect(counts).to eq({
      "/smartanswer/y/count" => 12,
    })
  end

  it "Doesn't add up counts from separate days" do
    write_lines("#{counts_dir}/#{default_day}/count_1.csv.gz", [
      '05 /smartanswer/y/count GET 200 origin,5',
    ])
    write_lines("#{counts_dir}/20150822/count_2.csv.gz", [
      '06 /smartanswer/y/count GET 200 origin,7',
    ])

    record_stderr
    day_dir = "#{counts_dir}/#{default_day}"
    counts = SuccessfulAccessCalculator.new($tempdir).send(:count_successes_for_day, day_dir)

    expect(recorded_stderr).to match("Processing counts from .*/#{default_day}/count_1\.csv")
    expect(recorded_stderr).not_to match("count_2\.csv")
    expect(counts).to eq({
      "/smartanswer/y/count" => 5,
    })
  end
end
