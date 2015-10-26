require_relative 'config'

# if a 404 has happened and it should be a 200
# update statsd and send a logstasher formatted
# json document to standard out

masterlist = ARGV[0]

known_good = []
CSV.foreach(masterlist, 'r') do |row| # assume each line sorted by basepath
  known_good << row[0]
end

# the cdn log line is expected to be in the following format
# IP "-" "-" ... DD MMM YYYY TIME ZONE METHOD BASEPATH STATUS BACKEND
$stdin.each_line do |line|
  begin
    fragment = line.split
  rescue ArgumentError # weird characters in url
    next
  end
  next if fragment[-2] != "404"

  path_of_404 = fragment[-3]
  if known_good.include?(path_of_404)
    register_404
    $stdout.puts logstash_format_json(fragment)
    next
  end
end
