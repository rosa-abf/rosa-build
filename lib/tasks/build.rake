require 'highline/import'
require 'open-uri'

namespace :build do
  desc "Build projects from list"
  task :projects => :environment do
    source = ENV['SOURCE'] || 'http://dl.dropbox.com/u/984976/rebuild_list.txt'
    owner = User.find_by_uname!(ENV['OWNER'] || 'warpc')
    platform = Platform.find_by_name!(ENV['PLATFORM'] || 'rosa2012lts')
    arch = Arch.find_by_name!(ENV['ARCH'] || 'i586')

    say "START build projects from #{source} for platform=#{platform.name}, owner=#{owner.uname}, arch=#{arch.name}"
    open(source).readlines.each do |name|
      name.chomp!; name.strip! #; name.downcase!
      if p = Project.joins(:repositories).where('repositories.id IN (?)', platform.repositories).find_by_name(name)
        # Old code p.build_for(platform, owner, arch)
        say "== Build #{p.name} =="
      else
        say "== Not found #{name} =="
      end
      sleep 0.2
    end
    say 'DONE'
  end
end
