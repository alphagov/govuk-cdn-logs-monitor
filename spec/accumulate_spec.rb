require 'spec_helper'

describe "Accumulating new urls" do
  it "sorts the urls lexicographically for nicer differences" do
    `./accumulate.sh spec spec/fixtures/masterlist.csv`

    contents = file_contents('spec/fixtures/masterlist.csv')
    expect(contents).to eq("/make-a-sorn,\n/view-driving-licence,\n")
  end

  it "doesn't add duplicate basepaths" do
    `CSV_INTERVAL=1 ./accumulate.sh spec/fixtures spec/fixtures/masterlist.csv`

    contents = file_contents('spec/fixtures/masterlist.csv')
    expect(contents).to eq("/make-a-sorn,\n/view-driving-licence,\n")
  end
end
