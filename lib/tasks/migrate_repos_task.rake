namespace :repositories do

  desc "Migrate repositories from fs"
  task :migrate => :environment do
    repo_dirs = Dir["/root/mandriva_main_git/*.git"]
    total = repo_dirs.length

    cooker = Platform.find_by_name!("cooker")
    main = cooker.repositories.find_by_name!("main")

    repo_dirs.each_with_index do |repo_dir, index|
      project_name = File.basename(repo_dir, ".git")

      puts "Creating project(#{index}/#{total}): #{project_name}"

      if main.projects.find_by_name(project_name)
        puts "\t Already created. Skipping"
        next
      end

      project = main.projects.create(:name => project_name, :unixname => project_name)

      puts "Executing: 'rm -rf #{project.git_repo_path}'"
      `rm -rf #{project.git_repo_path}`

      puts "Executing: 'cp -a #{repo_dir} #{project.git_repo_path}'"
      `cp -a #{repo_dir} #{project.git_repo_path}`

      puts ""
    end

  end

end
