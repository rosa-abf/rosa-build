require 'highline/import'
require 'open-uri'

namespace :import do
  desc "Load projects"
  task :projects => :environment do
    source = ENV['SOURCE'] || 'http://dl.dropbox.com/u/984976/package_list.txt'
    #owner = User.find_by_uname(ENV['OWNER_UNAME']) || Group.find_by_uname(ENV['OWNER_UNAME']) || User.first
    owner =  Group.find_by_uname("npp_team")
    platform = Platform.find_by_name("RosaNPP") # RosaNPP
    repo = platform.repositories.first rescue nil
    say "START import projects from '#{source}' for '#{owner.uname}'.#{repo ? " To repo '#{platform.name}/#{repo.name}'." : ''}"
    ask 'Press enter to continue'
    open(source).readlines.each do |name|
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

  namespace :sync do
    desc "Sync all repos"
    task :all do
      system("bundle exec rake import:sync:run RELEASE=official/2011 PLATFORM=mandriva2011 REPOSITORY=main")
      system("bundle exec rake import:sync:run RELEASE=official/2011 PLATFORM=mandriva2011 REPOSITORY=contrib")
      system("bundle exec rake import:sync:run RELEASE=official/2011 PLATFORM=mandriva2011 REPOSITORY=non-free")
      system("bundle exec rake import:sync:run RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=main")
      system("bundle exec rake import:sync:run RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=contrib")
      system("bundle exec rake import:sync:run RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=non-free")
    end

    task :run => [:rsync, :parse]

    desc "Rsync with mirror.yandex.ru"
    task :rsync => :environment do
      release = ENV['RELEASE'] || 'official/2011'
      repository = ENV['REPOSITORY'] || 'main'
      source = "rsync://mirror.yandex.ru/mandriva/#{release}/SRPMS/#{repository}/"
      destination = ENV['DESTINATION'] || File.join(APP_CONFIG['root_path'], 'mirror.yandex.ru', 'mandriva', release, 'SRPMS', repository)
      say "START rsync projects (*.src.rpm) from '#{source}' to '#{destination}'"
      if system "rsync -rtv --delete #{source} #{destination}" # TODO --include='*.src.rpm' --exclude='*'
        say 'Rsync ok!'
      else
        say 'Rsync failed!'
      end
      say 'DONE'
    end

    desc "Parse repository for changes"
    task :parse => :environment do
      release = ENV['RELEASE'] || 'official/2011'
      platform = Platform.find_by_name(ENV['PLATFORM'] || "mandriva2011")
      repository = platform.repositories.find_by_name(ENV['REPOSITORY'] || 'main')
      source = ENV['SOURCE'] || File.join(APP_CONFIG['root_path'], 'mirror.yandex.ru', 'mandriva', release, 'SRPMS', repository.name)
      owner = Group.find_or_create_by_uname(ENV['OWNER'] || 'import') {|g| g.owner = User.first}
      branch = "import_#{platform.name}"

      say 'START'
      Dir[File.join source, '{release,updates}', '*.src.rpm'].each do |srpm_file|
        say "=== Processing '#{srpm_file}'..."
        if name = `rpm -q --qf '[%{Name}]' -p #{srpm_file}` and $?.success? and name.present? and
           version = `rpm -q --qf '[%{Version}]' -p #{srpm_file}` and $?.success? and version.present?
          project_import = ProjectImport.find_by_name(name) || ProjectImport.by_name(name).first || ProjectImport.new(:name => name)
          if version != project_import.version.to_s and File.mtime(srpm_file) > project_import.file_mtime
            unless project = project_import.project
              if project = repository.projects.find_by_name(name) || repository.projects.by_name(name).first # fallback to speedup
                say "Found project '#{project.owner.uname}/#{project.name}'"
              elsif scoped = Project.where(:owner_id => owner.id, :owner_type => owner.class) and
                    project = scoped.find_by_name(name) || scoped.by_name(name).first
                repository.projects << project
                say "Add project '#{project.owner.uname}/#{project.name}' to '#{platform.name}/#{repository.name}'"
              else
                description = ::Iconv.conv('UTF-8//IGNORE', 'UTF-8', `rpm -q --qf '[%{Description}]' -p #{srpm_file}`)
                project = Project.create!(:name => name, :description => description) {|p| p.owner = owner}
                repository.projects << project
                say "Create project #{project.owner.uname}/#{project.name} in #{platform.name}/#{repository.name}"
              end
            end
            project.import_srpm(srpm_file, branch)
            say "New version (#{version}) for '#{project.owner.uname}/#{project.name}' successfully imported to branch '#{branch}'!"

            project_import.project = project
            project_import.version = version
            project_import.file_mtime = File.mtime(srpm_file)
            project_import.save!

            # TODO notify import.members

            say '=== Success!'
          else
            say '=== Not changed!'
          end
        else
          say '=== Fail!'
        end
      end
      say 'DONE'
    end
  end
end
