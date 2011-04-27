namespace :repositories do

  desc "Migrate repositories from fs"
  task :migrate => :environment do
    repos_dirs = Dir["/root/mandriva_main_git/*.git"]

    cooker = Platform.find_by_name!("cooker")
    main = cooker.repositories.find_by_name!("main")

    repos_dirs.each do |repo_dir|
      puts repo_dir
      puts File.basename(repos_dir, ".git")

      project_name = File.basename(repos_dir, ".git")

#      main.projects.create(:name => project_name, :unixname => project_name)
#      Dir
    end

  end

end
