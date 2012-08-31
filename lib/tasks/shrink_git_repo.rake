namespace :project do
  desc "Truncate blobs from git repo"
  task :remove_archives => :environment do
    raise 'Need set GIT_PROJECTS_DIR' if ENV['GIT_PROJECTS_DIR'].blank?
    abf_existing_log = File.open "#{ENV['CLONE_PATH']}/projects_with_abf_yml.log", 'w'
    projects = if uname = ENV['OWNER']
                 owner = User.find_by_uname(uname) || Group.find_by_uname(uname)
                 owner.projects
               else
                 Project.scoped
               end

    projects = projects.where :id => eval(ENV['PROJECT_ID']) if ENV['PROJECT_ID']
    total_count = projects.count
    FileUtils.mkdir_p "#{ENV['CLONE_PATH']}/archives" if total_count > 0
    begin_time = Time.now
    pr_count = 0
    projects.each_with_index do |project, ind|
      project_stats = "#{project.name_with_owner}: #{ind+1}/#{total_count}"
      if project.repo.commits.count == 0
        say "Skipping empty project #{project_stats}"
      else
        say "Start working with #{project_stats}"
        time = Time.now
        path = "#{ENV['CLONE_PATH'].chomp('/')}/repos/#{project.name_with_owner}"
        FileUtils.rm_rf path
        project_path = "#{ENV['GIT_PROJECTS_DIR']}/#{project.name_with_owner}/.git"
        system "git clone --mirror #{project_path} #{path}/.git"
        archives_exists = false
        Dir.chdir(path) do
          system 'git config --bool core.bare false && git checkout -f HEAD' # hack for refs/heads
          %w(tar.bz2 tar.gz bz2 rar gz tar tbz2 tgz zip Z 7z).each do |ext|
            archives_exists=true and break if `git log --all --format='%H' -- *.#{ext}`.present?
          end
        end
        if `cd #{path} && git log --all -- abf.yml`.present? # already have abf.yml in repo?
          message="Skipping project with abf.yml file #{project_stats}"
          say message
          abf_existing_log.puts message
          `rm -rf #{path}`
        elsif archives_exists.present?
          system "bin/calc_sha #{path} #{ENV['CLONE_PATH']}/archives" # FIXME change filename

          #####
          # This is dangerous !!!
          #system "rm -rf #{project_path} && git clone --bare #{path} #{project_path} && rm -rf #{path}"
          #####

          say "Worked with #{project.name_with_owner}: #{(Time.now - time).truncate} sec."
          pr_count +=1
        else
          message="Skipping project with no archives #{project_stats}"
          say message
          abf_existing_log.puts message
          `rm -rf #{path}`
        end
        say '-------------'
      end
    end
    say '======================='
    say "Total count of projects are #{total_count}"
    say "Finished with #{pr_count} project(s) in #{Time.at((Time.now - begin_time).truncate).gmtime.strftime('%R:%S')}"
    abf_existing_log.close
  end
end
