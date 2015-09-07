# coding: utf-8
# Work in progress

# process the cdn log for 200s that are pages on gov.uk, not files (eg, pdf, odt)

require 'pp'

File.readlines("cdn.log").lazy # Suitable for WIP. Really want to stream the data
  .map(&:split)
  .map {|line| [line[-1],line[-2]]} # only need the status and the basepath
  .select {|(status,basepath)| status == "200"} # all 200s
  .reject {|(status,basepath)| basepath[0..33] == "/government/uploads/system/uploads"} # no files
  .sort # heaviest usage might be best since those pages are priority
  .uniq # really want to count occurences
  # uniq ∘ sort is only needed in the WIP. This will really be pushing stuff to a DB/something else
  .tap {|x| PP.pp x}
