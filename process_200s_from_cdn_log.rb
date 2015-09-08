# coding: utf-8
# Work in progress

# process the cdn log for 200s that are pages on gov.uk, not files (eg, pdf, odt)

require 'pp'
require 'csv'

filename = ARGV[0]
if File.exists?(filename)
  raise "File already exists"
end

data = Hash.new(0)
$stdin.each_line do |line|
  begin
    fragment = line.split
  rescue ArgumentError
    next
  end

  status = fragment[-1]
  basepath = fragment[-2]
  if status[0] == "2"
    data[basepath] += 1
  end
end

CSV.open(filename,"w") do |csv|
  data.each do |basepath, count|
    if basepath.include?("/y/") && count < 100
      next
    elsif basepath.include?("?") && count < 100
      next
    end
    csv << [basepath, count]
  end
end
