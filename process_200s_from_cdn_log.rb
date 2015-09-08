# coding: utf-8
# Work in progress

# process the cdn log for 200s that are pages on gov.uk, not files (eg, pdf, odt)

require 'pp'
require 'csv'

data = Hash.new(0)

$stdin.readlines
  .map(&:split)
  .map {|line| [line[-1],line[-2]]} # only need the status and the basepath
  .select {|status,basepath| status == "200"} # all 200s
  .reject {|status,basepath| basepath[0..33] == "/government/uploads/system/uploads"} # no files
  .each {|status,basepath| data[basepath] += 1}

CSV.open("out.csv","w") do |csv|
  data.each do |basepath, count|
    csv << [basepath, count]
  end
end
