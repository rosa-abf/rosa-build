namespace :repositories do

  desc "Migrate repositories from fs"
  task :migrate => :environment do
    repo_dirs = Dir["/root/mandriva_main_git/*.git"]

    cooker = Platform.find_by_name!("cooker")
    main = cooker.repositories.find_by_name!("main")

    repo_dirs.each do |repo_dir|
      project_name = File.basename(repo_dir, ".git")

      puts "Creating project: #{project_name}"

      if main.projects.find_by_name(:name => project_name)
        puts "\t Already created. Skipping"
        next
      end

      project = main.projects.create(:name => project_name, :unixname => project_name)

      puts "Executing: 'rm -rf #{project.git_repo_path}'"
      `rm -rf #{project.git_repo_path}`
#      `cp -a #{repo_dir} #{project.git_repo_path}`
    end

  end

end
