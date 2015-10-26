require 'csv'
require 'json'
require 'uri'
require 'statsd-ruby'
require 'git'

def interval
  @csv_interval ||= (ENV['CSV_INTERVAL'].to_i || 7)
end

# the cdn log line is expected to be in the following format
# IP "-" "-" ... DD MMM YYYY TIME ZONE METHOD BASEPATH STATUS BACKEND
def parse_logline(logline)
  lines = logline.split(' ')
  return {
    ip: lines[0],
    time: lines[-9..-5].join(" "),
    method: lines[9],
    path: lines[10],
    status: lines[11],
    backend: lines[12],
  }
end

def logstash_format_json(logline)
  parsed_logline = parse_logline(logline)
  uri = URI.parse("https://www.gov.uk#{parsed_logline[:path]}")
  JSON.generate({
    "@fields"=> {
      "method"=>parsed_logline[:method],
      "path"=>uri.path,
      "query_string"=>uri.query,
      "status"=>404,
      "duration"=>0,
      "remote_addr"=>parsed_logline[:ip],
      "request"=>"#{parsed_logline[:method]} #{parsed_logline[:path]}",
      "length"=>"-"},
    "@tags"=>["request"],
    "@timestamp"=>DateTime.parse(parsed_logline[:time]),
    "@version"=>"1"
  })
end

def register_404
  increment_counter("govuk_cdn.404")
end

def increment_counter(counter_name)
  port = ENV['STATSDPORT'] || 8125
  s = Statsd.new("localhost", port)
  s.namespace = ENV["GOVUK_STATSD_PREFIX"]
  s.increment(counter_name)
end

def commit_changes(masterlist)
  repo_dir = '.'
  g = Git.open(repo_dir)
  g.add(masterlist)
  g.commit("#{Date.today} updates to masterlist")
  g.push
end
