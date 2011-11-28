require 'open-uri'

namespace :import do
  desc "Load projects"
  task :projects => :environment do
    open('http://dl.dropbox.com/u/984976/sorted4.txt').readlines.each do |name| # http://dl.dropbox.com/u/984976/PackageList.txt
      name.chomp!; name.downcase!
      name = name.match(/^([a-z\d_\-\+\.]+?)-(\d[a-z\d\-\.]+)\.src\.rpm$/)[1] # parse
      print "Import #{name}..."
      owner = User.find(1) # I am
      # owner = Group.find(1) # Core Team
      p = Project.find_or_create_by_name_and_name(name, name) {|p| p.owner = owner}
      puts p.persisted? ? "Ok!" : "Fail!"
    end
    puts 'DONE'
  end
end
