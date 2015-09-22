require 'spec_helper'

describe "Alert 404s" do
  before do
    $stdin.reopen('spec/fixtures/404.log', 'r')
  end

  it "sends logstasher formatted json to standard out" do
    result = `ruby lib/alert_if_404_url_present.rb spec/fixtures/masterlist.csv`
    r = JSON.parse(result)

    expect(r["@fields"]["path"]).to eq("/make-a-sorn")
    expect(r["@fields"]["method"]).to eq("GET")
    expect(r["@fields"]["remote_addr"]).to eq("192.168.0.1")
    expect(r["@timestamp"]).to eq("2016-01-01T00:00:02+00:00")
  end

  it "increments statsd metric when a 404 happens" do
    socket = UDPSocket.new
    socket.bind("localhost", 8126)

    `GOVUK_STATSD_PREFIX=govuk.statsd.prefix STATSDPORT=8126 ruby lib/alert_if_404_url_present.rb spec/fixtures/masterlist.csv`

    received = socket.recv(37)
    expect(received).to eq("govuk.statsd.prefix.govuk_cdn.404:1|c")
  end
end
