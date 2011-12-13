require 'highline/import'
require 'open-uri'

namespace :import do
  desc "Load projects"
  task :projects => :environment do
    owner = User.find_by_uname(ENV['OWNER_UNAME']) || Group.find_by_uname(ENV['OWNER_UNAME']) || User.first
    platform = Platform.find_by_name(ENV['PLATFORM_NAME']) # 'mandriva2011'
    repo = platform.repositories.first rescue nil
    say "START import projects for '#{owner.uname}'.#{repo ? " To repo '#{platform.name}/#{repo.name}'." : ''}"
    ask 'Press enter to continue'
    open('http://dl.dropbox.com/u/984976/package_list.txt').readlines.each do |name|
      name.chomp!; name.strip! #; name.downcase!
      # name = name.match(/^([a-z\d_\-\+\.]+?)-(\d[a-z\d\-\.]+)\.src\.rpm$/)[1] # parse
      print "Import '#{name}'..."
      p = Project.find_or_create_by_name_and_owner_type_and_owner_id(name, owner.class.to_s, owner.id)
      print p.persisted? ? "Ok!" : "Fail!"
      if repo
        print " Add to repo '#{platform.name}/#{repo.name}'."
        repo.projects << p rescue print ' Fail!'
      end
      puts
    end
    say 'DONE'
  end
end
