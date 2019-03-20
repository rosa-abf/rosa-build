#!/usr/bin/env ruby
# git_dir_projects[0] dest_git_path[1] clone_path[2] owner[3] project_name[4]

require 'fileutils'
require 'digest'

token = '[CENSORED]'

owners = ARGF.argv[3] || '[a-z0-9_]*'
project_names = ARGF.argv[4] || '[a-zA-Z0-9_\-\+\.]*'

begin_time = Time.now
pr_count = total_count = 0

Dir.chdir ARGF.argv[0]
Dir.glob(owners).each do |owner|
  Dir.chdir "#{ARGF.argv[0]}/#{owner}"
  Dir.glob(project_names).each do |project|
    name_with_owner = "#{owner}/#{project.chomp('.git')}"
    project_path = "#{ARGF.argv[0]}/#{name_with_owner}.git"
    dest_project_path = "#{ARGF.argv[1]}/#{name_with_owner}.git"
    time, total_count = Time.now, total_count + 1
    Dir.chdir project_path
    project_stats = "#{name_with_owner}: #{total_count}"
    if system('git log -n 1 --oneline > /dev/null 2>&1') == false
      p "Skipping empty project #{project_stats}"
    else
      p "Start working with #{project_stats}"
      path = "#{ARGF.argv[2].chomp('/')}/repos/#{name_with_owner}"
      FileUtils.rm_rf path
      #-- hack for refs/heads (else git branch return only master)
      system "git clone --mirror #{project_path} #{path}/.git"
      system "cd #{path} && git config --bool core.bare false && git checkout -f HEAD"
      #--
      Dir.chdir(path)

      unless `git log --all --format='%H' -- *.{bz2,rar,gz,tar,tbz2,tgz,zip,Z,7z,xz,lzma}`.empty?
        system "git filter-branch -d /dev/shm/git_task --tree-filter \"/rosa-build/bin/file-store.rb #{token}\" --prune-empty --tag-name-filter cat -- --all"
        #####
        # This is dangerous !!!
        system "rm -rf #{dest_project_path} && git clone --bare #{path} #{dest_project_path}"
        #####

        p "Worked with #{name_with_owner}: #{(Time.now - time).truncate} sec."
        pr_count +=1
      else
        p "Skipping project with no archives #{project_stats}"
      end
      `rm -rf #{path} && cd #{dest_project_path} && git gc --prune=now`
    end
    p '-------------'
  end
end
p '======================='
p "Total count of projects are #{total_count}"
p "Finished work with #{pr_count} project(s) in #{Time.at((Time.now - begin_time).truncate).gmtime.strftime('%R:%S')}"
