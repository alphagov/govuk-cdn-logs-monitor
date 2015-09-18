require_relative 'config'

masterlist = ARGV[0]

known_good = []
CSV.foreach(masterlist, 'r') do |row| # assume each line sorted by basepath
  known_good << row[0]
end

$stdin.each_line do |line|
  begin
    fragment = line.split
  rescue ArgumentError # weird characters in url
    next
  end
  next if fragment[-1] != "404"

  _404_path = fragment[-2]
  if known_good.any? {|x| x == _404_path}
    register_404
    $stdout.puts logstash_format_json(fragment)
    next
  end
end