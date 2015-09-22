require 'spec_helper'

describe 'Process gz logs' do
  it 'uncompresses files before processing' do
    `./process_gz_logs.sh spec/fixtures /tmp`

    contents = file_contents('/tmp/20160101.csv')
    expect(contents.include?('/compressed-log-file,7')).to eq(true)

    contents = file_contents('/tmp/20160102.csv')
    expect(contents.include?('/compressed-log-file-2,5')).to eq(true)
  end
end
