# Work in progress

# process the cdn log for 200s that are pages on gov.uk, not files (eg, pdf, odt)

require 'pp'

all_200s = []

File.readlines("cdn.log").each do |line|
  PP.pp line
  fragments = line.split(' ')
  all_200s << fragments[-2] if fragments[-1] == "200"
end

page_200s = all_200s.reject {|base_path| base_path[0..33] == "/government/uploads/system/uploads"}

PP.pp page_200s.sort.uniq
