require 'spec_helper'

describe "Process 2XXs" do
  it "doesn't overwrite existing files" do
    `ruby lib/process_200s_from_cdn_log.rb spec/fixtures/existing.csv`

    contents = file_contents('/tmp/err.txt')
    expect(contents.include?('File already exists')).to eq(true)
  end

  it "saves the basepaths and counts to the specified file" do
    $stdin.reopen('spec/fixtures/yesterday.log','r')

    `ruby lib/process_200s_from_cdn_log.rb /tmp/successful.csv`

    contents = file_contents('/tmp/successful.csv')
    expect(contents.include?('/make-a-sorn,4')).to eq(true)
    expect(contents.include?('/view-driving-licence,3')).to eq(true)
  end

  it "doesn't include urls with potentially personal information" do
    $stdin.reopen('spec/fixtures/personal-info.log','r')

    `ruby lib/process_200s_from_cdn_log.rb /tmp/successful.csv`

    contents = file_contents('/tmp/successful.csv')
    expect(contents.include?('/y/')).to eq(false)
    expect(contents.include?('?')).to eq(false)
  end

  it "calculates the correct csv name from the log name" do
    # picks cdn-govuk.log-20160102 from spec/fixtures
    `./nightly_run.sh spec/fixtures /tmp`

    contents = file_contents('/tmp/20160102.csv')
    expect(contents.include?('/make-a-sorn,4')).to eq(true)
    expect(contents.include?('/view-driving-licence,3')).to eq(true)
  end
end
