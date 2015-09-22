require 'csv'
require 'json'
require 'uri'
require 'statsd-ruby'
require 'git'

def interval
  @csv_interval ||= (ENV['CSV_INTERVAL'].to_i || 7)
end

# the cdn log line is expected to be in the following format
# IP "-" "-" ... DD MMM YYYY TIME ZONE METHOD BASEPATH STATUS
def time(logline)
  DateTime.parse(logline[-8..-4].join(" "))
end

def logstash_format_json(logline)
  uri = URI.parse("https://www.gov.uk#{logline[-2]}")
  JSON.generate({
    "@fields"=> {
      "method"=>logline[-3],
      "path"=>uri.path,
      "query_string"=>uri.query,
      "status"=>404,
      "duration"=>0,
      "remote_addr"=>logline[0],
      "request"=>"#{logline[-3]} #{logline[-2]}",
      "length"=>"-"},
    "@tags"=>["request"],
    "@timestamp"=>time(logline),
    "@version"=>"1"
  })
end

def register_404
  port = ENV['STATSDPORT'] || 8125
  s = Statsd.new("localhost", port)
  s.namespace = ENV["GOVUK_STATSD_PREFIX"]
  s.increment("govuk_cdn.404")
end

def commit_changes(masterlist)
  repo_dir = '.'
  g = Git.open(repo_dir)
  g.add(masterlist)
  g.commit("#{Date.today} updates to masterlist")
  g.push
end
