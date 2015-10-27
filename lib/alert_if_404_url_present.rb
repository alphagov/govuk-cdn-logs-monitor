require_relative 'config'

# if a 404 has happened and it should be a 200
# update statsd and send a logstasher formatted
# json document to standard out

masterlist = ARGV[0]

known_good = []
CSV.foreach(masterlist, 'r') do |row| # assume each line sorted by basepath
  known_good << row[0]
end

$stdin.each_line do |line|
  parsed_logline = parse_logline(line)
  next if parsed_logline[:status] != "404"

  path_of_404 = parsed_logline[:path]
  if known_good.include?(path_of_404)
    register_404
    $stdout.puts logstash_format_json(line)
    next
  end
end
