#!/usr/bin/ruby

# This file is part of gitstats.rb.
#
# gitstats.rb is free software: you can redistribute it and/or modify it under the terms
# of the GNU General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# gitstats.rb is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# gitstats.rb (file COPYING in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

home = `git rev-parse --show-toplevel`.strip
log = `git log --pretty=format:"####%aN####%ct####%H####%s" --reverse --summary --numstat --encoding=UTF-8 --no-renames`

class Details #{{{
  attr_accessor :added, :deleted, :type

  def initialize
    @type = 'modify'
    @added = 0
    @deleted = 0
  end
end #}}}

class Commit  #{{{
  attr_reader :author, :date, :subject, :files, :id
  def initialize(author,date,id,subject)
    @author = author
    @date = date
    @id = id
    @subject = subject
    @files = {}
  end
end #}}}

commits = []
log.each_line do |l|
  if l =~ /^####(.*)####(\d+)####([a-z0-9]+)####(.*)$/
    timestamp = Time.at($2.to_i)
    author = $1
    subject = $4
    id = $3
    commits << Commit.new(author,timestamp,id,subject)
  else
    if l.strip =~ /^(\d+)\t(\d+)\t(.*)$/
      entry = (commits.last.files[$3] ||= Details.new)
      entry.added = $1.to_i
      entry.deleted = $2.to_i
    elsif l.strip =~ /^(\w+) mode (\d+) (.*)$/
      entry = (commits.last.files[$3] ||= Details.new)
      entry.type = $1
    else
    end
  end
end

files = []
commits.each do |c|
  c.files.each do |k,v|
    files << k
  end
end
files = files.uniq.sort

### Determine last run
lastrun = if File.exists? "#{home}/.statsrun"
  lr = File.read("#{home}/.statsrun").strip
else
  commits.last.id
end
File.write("#{home}/.statsrun",commits.last.id)
files_since_last_run = nil
commits.each do |c|
  if c.id == lastrun
    files_since_last_run = []
  else
    if files_since_last_run.is_a? Array
      c.files.each do |k,v|
        files_since_last_run << k
      end
    end
  end
end
files_since_last_run = files_since_last_run.uniq.sort

### delete files that are not on whitelist, handle adding new files to repo gracefully (they are added to the whitelist)
if File.exists? "#{home}/.whitelist"
  whitelist = File.readlines("#{home}/.whitelist").map{|l| l.strip}
  blacklist = File.exists?("#{home}/.blacklist") ? File.readlines("#{home}/.blacklist").map{|l| l.strip} : []
  newfiles = files_since_last_run - blacklist
  checklist = (whitelist + newfiles).uniq.sort
  commits.each do |c|
    c.files.delete_if do |k,v|
      !(checklist.include?(k))
    end
  end
  if (blacklist = files - checklist).any?
    text = [ "### the .blacklist is purely for documentation purposes", "### add lines from here to the .whitelist to make a difference", "" ]
    File.write("#{home}/.blacklist",(text + blacklist.sort).join("\n") + "\n")
  end
  if (checklist - whitelist).any?
    File.write("#{home}/.whitelist",checklist.join("\n") + "\n")
    File.write("#{home}/.whitelist.old",whitelist.join("\n") + "\n")
  end
else
  File.write("#{home}/.whitelist",files.join("\n") + "\n")
end

### commits per author
authors = {}
commits.each do |c|
  authors[c.author] ||= []
  authors[c.author] << c
end
authorfilter = if File.exists? "#{home}/.statsauthors"
  sa = File.readlines("#{home}/.statsauthors").map{|l| (l =~ /^###/ || l =~ /^\s*$/) ? nil : l}.compact
  if (newauthors = authors.keys - sa.map{|x| x.strip}).any?
    File.open("#{home}/.statsauthors", 'a') { |f| f.write newauthors.join("\n") + "\n" }
  end
  parent = nil
  sa.inject({}) do |i,a|
    if a =~ /^\s/
      i[parent] << a.strip
    else
      i[a.strip] = []
      parent = a.strip
    end
    i
  end
else
  text = [ "### authors that are not in this file, are not in the stats", "### indent author lines (1+ \\s characters) to define aliases", "" ]
  File.write("#{home}/.statsauthors",(text + authors.keys).join("\n") + "\n")
  authors.keys.map{|k| [k,[]]}.to_h
end
newauthors = {}
authorfilter.each do |author,authoraliases|
  newauthors[author] = authors[author]
  authoraliases.each{ |authoralias| newauthors[author] += authors[authoralias] }
end
authors = newauthors



### stats
funique = {}
files = {}
lines = {}
ftypes = {}
authors.each do |a,c|
  lines[a] ||= {}
  files[a] ||= {}
  ftypes[a] ||= {}
  funique[a] ||= []
  c.each do |comm|
    comm.files.each do |fname,details|
      lines[a]['added'] ||= 0
      lines[a]['added'] += details.added
      lines[a]['deleted'] ||= 0
      lines[a]['deleted'] += details.deleted
      fname =~ /\.([a-zA-Z0-9]*)$/
      ftype = $1||'---'
      ftypes[a][ftype] ||= [0,0,0]
      ftypes[a][ftype][1] += details.added
      ftypes[a][ftype][2] += details.deleted
      unless funique[a].include?(fname)
        ftypes[a][ftype][0] += 1
        files[a]['unique'] ||= 0
        files[a]['unique'] += 1
        funique[a] << fname
      end
      files[a][details.type] ||= 0
      files[a][details.type] += 1
    end
  end
end

statstxt = ""
authors.each do |a,c|
  statstxt << "#{a} (#{c.length} commits)\n"
  lines[a].each do |k,v|
    statstxt << "    Lines #{k}:\t#{v}\n"
  end
  files[a].each do |k,v|
    statstxt << "    Files #{k}:\t#{v}\n"
  end
  statstxt << "    By File Type:\n"
  ftypes[a].each do |k,v|
    statstxt << "        '#{k}':\t#{v[0]} unique,\t#{v[1]} lines added,\t#{v[2]} lines deleted\n"
  end
end

File.write("#{home}/.stats",statstxt)
