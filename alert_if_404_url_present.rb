require 'csv'

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
    puts "************** ALERT #{_404_path} is 404ing"
    next
  end
end
