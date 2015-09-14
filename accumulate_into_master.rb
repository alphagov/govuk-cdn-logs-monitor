require 'csv'

masterlist = ARGV[0]
_200s_directory = ARGV[1]
accumulator = Hash.new(0)

# read in current master list
CSV.foreach(masterlist, 'r') do |row|
  accumulator[row[0]] += row[1].to_i
end

# update frequency of 200 responses
Dir["#{_200s_directory}/*.csv"].each do |csv|
  CSV.foreach(csv, 'r') do |row|
    accumulator[row[0]] += row[1].to_i
  end
end

# write out updated master list
CSV.open(masterlist, 'w') do |csv|
  accumulator.each do |k,v|
    csv << [k, v]
  end
end
