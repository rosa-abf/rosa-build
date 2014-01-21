require 'highline/import'
require 'open-uri'

namespace :import do
  desc "Load projects"
  task projects: :environment do
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

  # bundle exec rake import:srpm RAILS_ENV=production BASE=/share/platforms/naulinux5x_personal/tmp/SRPMS LIST=https://dl.dropbox.com/u/984976/nauschool5x.srpms.txt OWNER=naulinux PLATFORM=naulinux REPO=main CLEAR=true HIDDEN=true > log/srpm_naulinux.log &
  desc 'Import SRPMs as projects'
  task srpm: :environment do
    base = ENV['BASE'] || '/share/alt_repos/rsync'
    list = ENV['LIST'] #|| 'https://dl.dropbox.com/u/984976/alt_import.txt'
    mask = ENV['MASK'] || '*.src.rpm'
    hidden = ENV['HIDDEN'] == 'true' ? true : false
    owner = User.find_by_uname(ENV['OWNER']) || Group.find_by_uname!(ENV['OWNER'] || 'altlinux')
    platform = Platform.find_by_name!(ENV['PLATFORM'] || 'altlinux5')
    repo = platform.repositories.find_by_name!(ENV['REPO'] || 'main')
    clear = ENV['CLEAR'] == 'true' ? true : false

    say "START import projects from '#{base}' using '#{list || mask}' for '#{owner.uname}' to repo '#{platform.name}/#{repo.name}'."
    repo.project_to_repositories.clear if clear
    (list ? open(list).readlines.map{|n| File.join base, n.chomp.strip} : Dir[File.join base, mask]).each do |srpm_file|
      print "Processing '#{srpm_file}'... "
      if name = `rpm -q --qf '[%{Name}]' -p #{srpm_file}` and $?.success? and name.present?
        if clear # simply add
          project = Project.find_or_create_by_name_and_owner_type_and_owner_id(name, owner.class.to_s, owner.id)
          repo.projects << project rescue nil
        else # check if project already added
          if project = repo.projects.find_by_name(name) || repo.projects.by_name(name).first # fallback to speedup
            print "Found project '#{project.name_with_owner}' in '#{platform.name}/#{repo.name}'."
          elsif scoped = Project.where(owner_id: owner.id, owner_type: owner.class) and
                project = scoped.find_by_name(name) || scoped.by_name(name).first
            begin
              repo.projects << project rescue nil
            rescue Exception => e
              print "Add project '#{project.name_with_owner}' to '#{platform.name}/#{repo.name}' FAILED: #{e.message}."
            else
              print "Add project '#{project.name_with_owner}' to '#{platform.name}/#{repo.name}' OK."
            end
          else
            description = `rpm -q --qf '[%{Description}]' -p #{srpm_file}`.scrub('')
            project = Project.create!(name: name, description: description) {|p| p.owner = owner}
            repo.projects << project rescue nil
            print "Create project #{project.name_with_owner} in #{platform.name}/#{repo.name} OK."
          end
        end
        project.update_attributes(visibility: 'hidden') if hidden
        project.import_srpm(srpm_file, platform.name)
        print " Code import complete!"
      else
        print 'RPM Error!'
      end
      puts
    end
    say 'DONE'
  end

  namespace :sync do
    desc "Sync all repos"
    task all: :environment do
      # system("bundle exec rake import:sync:run RELEASE=official/2011 PLATFORM=mandriva2011 REPOSITORY=main")
      # system("bundle exec rake import:sync:run RELEASE=official/2011 PLATFORM=mandriva2011 REPOSITORY=contrib")
      # system("bundle exec rake import:sync:run RELEASE=official/2011 PLATFORM=mandriva2011 REPOSITORY=non-free")
      #system("bundle exec rake import:sync:run RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=main")
      #system("bundle exec rake import:sync:run RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=contrib")
      #system("bundle exec rake import:sync:run RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=non-free")
      system("bundle exec rake import:sync:run SOURCE=rsync://mirror.yandex.ru/fedora-epel/6/SRPMS/ DESTINATION=#{File.join(APP_CONFIG['root_path'], 'mirror.yandex.ru', 'fedora-epel', '6', 'SRPMS')} PLATFORM=server_personal REPOSITORY=main OWNER=server BRANCH=import")
      system("bundle exec rake import:sync:run SOURCE=rsync://rh-mirror.redhat.com/redhat/linux/enterprise/6Server/en/os/SRPMS/ DESTINATION=#{File.join(APP_CONFIG['root_path'], 'rh-mirror.redhat.com', 'redhat', 'linux', 'enterprise', '6Server', 'en', 'os', 'SRPMS')} PLATFORM=server_personal REPOSITORY=main OWNER=server BRANCH=import")
    end

    task run: [:rsync, :parse]

    desc "Rsync with mirror.yandex.ru"
    task rsync: :environment do
      release = ENV['RELEASE'] || 'official/2011'
      repository = ENV['REPOSITORY'] || 'main'
      source = ENV['SOURCE'] || "rsync://mirror.yandex.ru/mandriva/#{release}/SRPMS/#{repository}/"
      destination = ENV['DESTINATION'] || File.join(APP_CONFIG['root_path'], 'mirror.yandex.ru', 'mandriva', release, 'SRPMS', repository)
      say "START rsync projects (*.src.rpm) from '#{source}' to '#{destination}' (#{Time.now.utc})"
      if system "rsync -rtv --delete --exclude='backports/*' --exclude='testing/*' #{source} #{destination}" # --include='*.src.rpm'
        say 'Rsync ok!'
      else
        say 'Rsync failed!'
      end
      say "DONE (#{Time.now.utc})"
    end

    desc "Parse repository for changes"
    task parse: :environment do
      release = ENV['RELEASE'] || 'official/2011'
      platform = Platform.find_by_name(ENV['PLATFORM'] || "mandriva2011")
      repository = platform.repositories.find_by_name(ENV['REPOSITORY'] || 'main')
      source = ENV['DESTINATION'] || File.join(APP_CONFIG['root_path'], 'mirror.yandex.ru', 'mandriva', release, 'SRPMS', repository.name, '{release,updates}')
      owner = Group.find_or_create_by_uname(ENV['OWNER'] || 'import') {|g| g.name = g.uname; g.owner = User.first}
      branch = ENV['BRANCH'] || "import_#{platform.name}"

      say "START (#{Time.now.utc})"
      Dir[File.join source, '*.src.rpm'].each do |srpm_file|
        print "Processing '#{srpm_file}'... "
        if name = `rpm -q --qf '[%{Name}]' -p #{srpm_file}` and $?.success? and name.present? and
           version = `rpm -q --qf '[%{Version}-%{Release}]' -p #{srpm_file}` and $?.success? and version.present?
          project_import = ProjectImport.find_by_name_and_platform_id(name, platform.id) || ProjectImport.by_name(name).where(platform_id: platform.id).first || ProjectImport.new(name: name, platform_id: platform.id)
          if version != project_import.version.to_s and File.mtime(srpm_file) > project_import.file_mtime
            unless project = project_import.project
              if platform.personal? # search project through owner # used for testhat
                project = Project.find_or_create_by_name_and_owner_type_and_owner_id(name, owner.class.to_s, owner.id)
                print "Use project #{project.name_with_owner}. "
              else # search project through repository
                if project = repository.projects.find_by_name(name) || repository.projects.by_name(name).first # fallback to speedup
                  print "Found project #{project.name_with_owner} in #{platform.name}/#{repository.name}. "
                elsif scoped = Project.where(owner_id: owner.id, owner_type: owner.class) and
                      project = scoped.find_by_name(name) || scoped.by_name(name).first
                  repository.projects << project
                  print "Add project #{project.name_with_owner} to #{platform.name}/#{repository.name}. "
                else
                  description = `rpm -q --qf '[%{Description}]' -p #{srpm_file}`.scrub('')
                  project = Project.create!(name: name, description: description) {|p| p.owner = owner}
                  repository.projects << project
                  print "Create project #{project.name_with_owner} at #{platform.name}/#{repository.name}. "
                end
              end
            end
            project.import_srpm(srpm_file, branch)
            print "New version (#{version}) for #{project.name_with_owner} successfully imported to branch #{branch}! "

            project_import.project = project
            # project_import.platform = platform
            project_import.version = version
            project_import.file_mtime = File.mtime(srpm_file)
            project_import.save!

            # TODO notify import.members

            print 'Ok!'
          else
            print 'Not updated!'
          end
        else
          print 'RPM Error!'
        end
        puts
      end
      say "DONE (#{Time.now.utc})"
    end
  end
end
