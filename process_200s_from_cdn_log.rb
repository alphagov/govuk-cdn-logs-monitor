# coding: utf-8
# Work in progress

# process the cdn log for 200s that are pages on gov.uk, not files (eg, pdf, odt)

require 'pp'
require 'sqlite3'

def connect_to_db
  db = SQLite3::Database.open "basepath200s.db"
  db.execute "CREATE TABLE IF NOT EXISTS basepaths(basepath TEXT unique, count INT DEFAULT 0)"
  db
end

def basepath_accessed(basepath, db)
  db.execute("insert or ignore into basepaths values (?, 0)", basepath)
  res = db.execute("select count from basepaths where basepath=?", basepath)
  db.execute("update basepaths set count = ? where basepath = ?", res[0][0]+1, basepath)
end

def show_db_state(db)
  db.execute("select * from basepaths order by count DESC") do |row|
    PP.pp row
  end
end

begin
  db = connect_to_db

  File.readlines("cdn.log") # Suitable for WIP. Really want to stream the data
    .map(&:split)
    .map {|line| [line[-1],line[-2]]} # only need the status and the basepath
    .select {|(status,basepath)| status == "200"} # all 200s
    .reject {|(status,basepath)| basepath[0..33] == "/government/uploads/system/uploads"} # no files
    .each {|(status,basepath)| basepath_accessed(basepath, db)}

  show_db_state(db)

rescue SQLite3::Exception => e
  puts e
ensure
  db.close if db
end
