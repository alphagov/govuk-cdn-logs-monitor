require_relative 'config'

# add basepaths from the processed csv files into the masterlist
# all basepaths in the masterlist should never 404

csv_directory = ARGV[0]
masterlist = ARGV[1]
accumulator = []

# read in current master list
CSV.foreach(masterlist, 'r') do |row|
  accumulator << row[0]
end

day_zeroes = Dir["#{csv_directory}/*.csv"]
week_later = day_zeroes[interval()..-1] || []

# intersection of urls 1 week apart get added to the masterlist
week_later.zip(day_zeroes).each do |finish, start|
  a = []; CSV.foreach(start,'r') do |row|
    a << row[0]
  end
  b = []; CSV.foreach(finish,'r') do |row|
    b << row[0]
  end
  accumulator += (a & b) # append the common basepaths
end

# write out updated master list
accumulator.uniq!
accumulator.sort!

CSV.open(masterlist, 'w') do |csv|
  accumulator.each do |k,v|
    csv << [k, v]
  end
end
