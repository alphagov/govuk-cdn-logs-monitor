require 'spec_helper'
require 'first_last_success_calculator'

describe "Finding the first and last sucessful accesses" do
  def daily_successes_dir
    "#{$tempdir}/successes/daily"
  end

  def first_last
    read_lines("#{$tempdir}/successes/first_last")
  end

  def first_last_sources
    read_lines("#{$tempdir}/successes/first_last_sources")
  end

  def prepare_daily_successes(data)
    counts_dir = "#{$tempdir}/successes"
  end

  it "produces two output lines for a single access" do
    write_lines("#{daily_successes_dir}/successes_20150821", [
      "/accessed_once 20150821",
      "/also_accessed_once 20150821",
    ])

    record_stderr
    FirstLastSuccessCalculator.new($tempdir).process

    expect(first_last).to eq([
      "/accessed_once 20150821",
      "/accessed_once 20150821",
      "/also_accessed_once 20150821",
      "/also_accessed_once 20150821",
    ])
    expect(first_last_sources).to eq([
      "#{daily_successes_dir}/successes_20150821 53",
    ])
    expect(recorded_stderr).to match("#{daily_successes_dir}/successes_20150821")
  end

  it "produces only the first and last access" do
    write_lines("#{daily_successes_dir}/successes_20150821", [
      "/accessed_three_times 20150821",
    ])
    write_lines("#{daily_successes_dir}/successes_20150822", [
      "/accessed_three_times 20150822",
    ])
    write_lines("#{daily_successes_dir}/successes_20150828", [
      "/accessed_three_times 20150828",
    ])

    record_stderr
    FirstLastSuccessCalculator.new($tempdir).process

    expect(first_last).to eq([
      "/accessed_three_times 20150821",
      "/accessed_three_times 20150828",
    ])
    expect(first_last_sources).to eq([
      "#{daily_successes_dir}/successes_20150821 31",
      "#{daily_successes_dir}/successes_20150822 31",
      "#{daily_successes_dir}/successes_20150828 31",
    ])
    expect(recorded_stderr).to match("#{daily_successes_dir}/successes_20150821")
    expect(recorded_stderr).to match("#{daily_successes_dir}/successes_20150822")
    expect(recorded_stderr).to match("#{daily_successes_dir}/successes_20150828")
  end
end
