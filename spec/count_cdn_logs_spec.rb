require 'spec_helper'
require 'count_cdn_logs'

describe "Counting CDN logs" do
  it "counts items in all logs" do
    record_stderr
    CountCdnLogs.new('spec/fixtures/good_logs', $tempdir).update

    expect(recorded_stderr).to match("cdn-govuk.log-20150821.gz")
    expect(recorded_stderr).to match("cdn-govuk.log-20150822.gz")
    expect(recorded_stderr).to match("cdn-govuk.log-20150823")
    expect(recorded_stderr).to match("cdn-govuk.log-20150829")

    count_file_for_29th = "#{$tempdir}/raw_counts/daily/20150829/count_cdn-govuk.log-20150829.csv"
    expect(read_lines(count_file_for_29th)).to eq([
      '05 /a-url GET 200 origin,1',
      '05 /a-url-with-unicode-€ GET 200 origin,1',
    ])
  end
end
