namespace :repositories do

  desc "Migrate repositories from fs"
  task migrate: :environment do
    repo_dirs = Dir["/root/mandriva_main_git/*.git"]
    total = repo_dirs.length

    cooker = Platform.find_by! name: "cooker"
    main = cooker.repositories.find_by! name: "main"

    repo_dirs.each_with_index do |repo_dir, index|
      project_name = File.basename(repo_dir, ".git")

      puts "Creating project(#{index}/#{total}): #{project_name}"

      if main.projects.find_by name: project_name
        puts "\t Already created. Skipping"
        next
      end

      project = main.projects.create(name: project_name, name: project_name)

      puts "Executing: 'rm -rf #{project.path}'"
      `rm -rf #{project.path}`

      puts "Executing: 'cp -a #{repo_dir} #{project.path}'"
      `cp -a #{repo_dir} #{project.path}`

      puts ""
    end

  end

end
