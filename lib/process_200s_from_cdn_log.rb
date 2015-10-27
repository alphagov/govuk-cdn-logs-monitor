# coding: utf-8

# process the cdn log for 200s on gov.uk

require_relative 'config'

filename = ARGV[0]
if File.exists?(filename)
  raise "File already exists"
end

data = Hash.new(0)
$stdin.each_line do |line|
  parsed_logline = parse_logline(line)

  status = parsed_logline[:status]
  basepath = parsed_logline[:path]
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
