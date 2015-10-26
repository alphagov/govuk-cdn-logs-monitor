# coding: utf-8

# process the cdn log for 200s on gov.uk

require_relative 'config'

filename = ARGV[0]
if File.exists?(filename)
  raise "File already exists"
end

data = Hash.new(0)
# the cdn log line is expected to be in the following format
# IP "-" "-" ... DD MMM YYYY TIME ZONE METHOD BASEPATH STATUS BACKEND
$stdin.each_line do |line|
  begin
    fragment = line.split
  rescue ArgumentError
    next
  end

  status = fragment[-2]
  basepath = fragment[-3]
  if status[0] == "2"
    data[basepath] += 1
  end
end

CSV.open(filename,"w") do |csv|
  data.each do |basepath, count|
    # smart answer basepaths can include personal information
    if basepath.include?("/y/") && count < 100
      next
    # search query parameters can include personal information
    elsif basepath.include?("?") && count < 100
      next
    end
    csv << [basepath, count]
  end
end
