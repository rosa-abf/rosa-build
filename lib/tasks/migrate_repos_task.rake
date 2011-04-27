namespace :repositories do

  desc "Migrate repositories from fs"
  task :migrate => :environment do
    repo_dirs = Dir["/root/mandriva_main_git/*.git"]

    cooker = Platform.find_by_name!("cooker")
    main = cooker.repositories.find_by_name!("main")

    repo_dirs.each do |repo_dir|
      puts repo_dir
      project_name = File.basename(repo_dir, ".git")
      puts project_name


#      main.projects.create(:name => project_name, :unixname => project_name)
#      Dir
    end

  end

end
