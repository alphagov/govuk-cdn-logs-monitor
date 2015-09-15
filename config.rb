require 'csv'
require 'json'
require 'statsd-ruby'
require 'git'

def register_404
  s = Statsd.new("localhost")
  s.namespace = ENV["GOVUK_STATSD_PREFIX"]
  s.increment('404')
end

def date(log_line)
  "#{log_line[-8]} #{log_line[-7]} #{log_line[-6]}"
end

def time(log_line)
  "#{log_line[-5]} #{log_line[-4]}"
end

def commit_changes(masterlist)
  repo_dir = '.'
  g = Git.open(repo_dir)
  g.add(masterlist)
  g.commit("#{Date.today} updates to masterlist")
  g.push
end
