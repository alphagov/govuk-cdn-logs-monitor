require 'csv'

masterlist = ARGV[0]
_200s_directory = ARGV[1]
accumulator = []

# read in current master list
CSV.foreach(masterlist, 'r') do |row|
  accumulator << row[0]
end

day_zeroes = Dir["#{_200s_directory}/*.csv"]
week_later = day_zeroes[7..-1] || []

# intersection of urls 1 week apart get added to the masterlist
day_zeroes.zip(week_later).each do |start,_end|
  if _end.nil?
    break
  end
  a = []; CSV.foreach(start,'r') do |row|
    a << row[0]
  end
  b = []; CSV.foreach(_end,'r') do |row|
    b << row[0]
  end
  accumulator += (a & b)
end

# write out updated master list
accumulator.uniq!
accumulator.sort!

CSV.open(masterlist, 'w') do |csv|
  accumulator.each do |k,v|
    csv << [k, v]
  end
end
