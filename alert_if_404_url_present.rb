require 'csv'
require 'statsd-ruby'
require 'json'

statsd_client = Statsd.new("localhost")
statsd_client.namespace = ENV["GOVUK_STATSD_PREFIX"]

def date(fragment)
  "#{fragment[-8]} #{fragment[-7]} #{fragment[-6]}"
end

def time(fragment)
  "#{fragment[-5]} #{fragment[-4]}"
end

known_good = []
CSV.foreach("masterlist.csv", 'r') do |row| # assume each line sorted by basepath
  known_good << row[0]
end

while line = gets do
  begin
    fragment = line.split
  rescue ArgumentError # weird characters in url
    next
  end
  next if fragment[-1] != "404"

  _404_path = fragment[-2]
  if known_good.any? {|x| x == _404_path}
    statsd_client.increment('404')
    result = { url: _404_path, method: fragment[-3],
               time: time(fragment), date: date(fragment)
             }
    puts JSON.generate(result)
    next
  end
end
