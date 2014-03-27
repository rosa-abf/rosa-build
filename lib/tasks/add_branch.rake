require 'highline/import'
require 'open-uri'

namespace :add_branch do
  desc 'Fork project branch'
  task :fork_branch, :path, :src_branch, :dst_branch do |t, args|
    tmp_path = File.join Dir.tmpdir, "#{Time.now.to_i}#{rand(1000)}"
    system("git clone #{args[:path]} #{tmp_path}")
    system("cd #{tmp_path} && git push origin :#{args[:dst_branch]}")
    system("cd #{tmp_path} && git checkout remotes/origin/#{args[:src_branch]} || git checkout master")
    system("cd #{tmp_path} && git checkout -b #{args[:dst_branch]} && git push origin HEAD")
    FileUtils.rm_rf tmp_path
  end

  desc "Add branch for group projects"
  task group: :environment do
    src_branch = ENV['SRC_BRANCH']
    dst_branch = ENV['DST_BRANCH']
    group = ENV['GROUP']
    say "START add branch #{dst_branch} from #{src_branch} in #{group} group"
    Group.find_by(uname: group).projects.find_each do |p|
      next if p.repo.branches.map(&:name).include?(dst_branch)
      next if p.repo.branches.map(&:name).exclude?(src_branch)
      say "===== Process #{p.name} project"
      Rake::Task['add_branch:fork_branch'].execute(path: p.path, src_branch: src_branch, dst_branch: dst_branch)
    end
    say 'DONE'
  end

  desc "Add branch for platform projects"
  task platform: :environment do
    src_branch = ENV['SRC_BRANCH'] || 'import_mandriva2011'
    dst_branch = ENV['DST_BRANCH'] || 'rosa2012lts'
    say "START add branch #{dst_branch} from #{src_branch}"
    Platform.find_by(name: dst_branch).repositories.each do |r|
      say "=== Process #{r.name} repo"
      r.projects.find_each do |p|
        next if p.repo.branches.map(&:name).include?(dst_branch)
        say "===== Process #{p.name} project"
        Rake::Task['add_branch:fork_branch'].execute(path: p.path, src_branch: src_branch, dst_branch: dst_branch)
      end
    end
    say 'DONE'
  end

  desc "Add branch for owner projects by list"
  task list: :environment do
    source = ENV['SOURCE'] || 'https://dl.dropbox.com/u/984976/texlive.txt'
    owner = User.find_by(uname: ENV['OWNER']) || Group.find_by!(uname: ENV['OWNER'] || 'import')
    platform = Platform.find_by!(name: ENV['PLATFORM'] || 'rosa2012.1')
    repo = platform.repositories.find_by!(name: ENV['REPO'] || 'main')
    src_branch = ENV['SRC_BRANCH'] || 'import_cooker'
    dst_branch = ENV['DST_BRANCH'] || 'rosa2012.1'
    say "START fork from #{src_branch} to #{dst_branch} branch using #{source} for #{owner.uname}. Add to repo '#{platform.name}/#{repo.name}'."
    open(source).readlines.each do |name|
      name.chomp!; name.strip!
      print "Fork branch for '#{name}'... "
      if p = Project.find_by_owner_and_name(owner.uname, name)
        # Rake::Task['add_branch:fork_branch'].execute(path: p.path, src_branch: src_branch, dst_branch: dst_branch)
        system "bundle exec rake add_branch:fork_branch[#{p.path},#{src_branch},#{dst_branch}] -s RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
        print 'Ok!'
        repo.projects << p rescue print ' Add to repo failed!'
      else
        print 'Not Found!'
      end
      puts
    end
    say 'DONE'
  end
end
