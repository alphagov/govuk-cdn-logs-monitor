require 'spec_helper'
require 'known_good_calculator'

describe "Calculating a list of known good accesses" do
  def first_last_file
    "#{$tempdir}/successes/first_last"
  end

  def known_good_urls_file
    "#{$tempdir}/output/known_good_urls"
  end

  it "adds urls to the known good list that are 7 days apart" do
    write_lines(first_last_file, [
      '/a-url 20141225',
      '/a-url 20150101',
    ])

    record_stderr
    KnownGoodCalculator.new($tempdir).process

    expect(read_lines(known_good_urls_file)).to eq([
      '/a-url',
    ])
    expect(recorded_stderr).to match("Calculating known good urls")
  end

  it "does add urls to the known good list that are 6 days apart" do
    write_lines(first_last_file, [
      '/a-url 20141226',
      '/a-url 20150101',
    ])

    record_stderr
    KnownGoodCalculator.new($tempdir).process

    expect(read_lines(known_good_urls_file)).to eq([])
    expect(recorded_stderr).to match("Calculating known good urls")
  end
end
