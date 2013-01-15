namespace :new_core do
  desc 'Sets bs_id field for all BuildList which use new_core'
  task :update_bs_id => :environment do
    say "[#{Time.zone.now}] Starting to update bs_id..."

    BuildList.select(:id).
      where(:new_core => true, :bs_id => nil).
      find_in_batches(:batch_size => 500) do | bls |

      puts "[#{Time.zone.now}] - where build_lists.id from #{bls.first.id} to #{bls.last.id}"
      BuildList.where(:id => bls.map(&:id), :bs_id => nil).
        update_all("bs_id = id")
    end

    say "[#{Time.zone.now}] done"
  end

  desc 'Publish mass-build 73'
  task :publish_mass_build_73 => :environment do
    say "[#{Time.zone.now}] Starting to publish mass-build 317..."

    bl = BuildList.where(:mass_build_id => 73).first
    platform_repository_folder = "#{bl.save_to_platform.path}/repository"
    BuildList.where(:mass_build_id => 73).
      where(:status => [
        BuildServer::SUCCESS,
        BuildList::FAILED_PUBLISH
      ]).
      order(:id).
      find_in_batches(:batch_size => 1) do | bls |

      bl = bls.first
      puts "[#{Time.zone.now}] - where build_lists.id #{bl.id}"

      sha1 = bl.results.find{ |r| r['file_name'] =~ /.*\.tar\.gz$/ }['sha1']

      system "cd #{platform_repository_folder} && curl -L -O #{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha1}"
      system "cd #{platform_repository_folder} && tar -xzf #{sha1}"
      system "rm -f #{platform_repository_folder}/#{sha1}"

      archive_folder = "#{platform_repository_folder}/archives"
      system "sudo chown root:root  #{archive_folder}/SRC_RPM/*"
      system "sudo chmod 0666       #{archive_folder}/SRC_RPM/*"
      system "sudo chown root:root  #{archive_folder}/RPM/*"
      system "sudo chmod 0666       #{archive_folder}/RPM/*"

      system "sudo mv #{archive_folder}/SRC_RPM/* #{platform_repository_folder}/SRPMS/main/release/"
      system "sudo mv #{archive_folder}/RPM/*     #{platform_repository_folder}/#{bl.arch.name}/main/release/"

      system "sudo rm -rf #{archive_folder}"
      bl.update_column(:status, BuildList::BUILD_PUBLISH)
    end

    say "[#{Time.zone.now}] done"
  end

  desc 'Extracts all rpms from BuildList container and updates BuildList::Package#sha1 field'
  task :update_packages => :environment do
    say "[#{Time.zone.now}] Starting to extract rpms..."

    token = User.find_by_uname('rosa_system').authentication_token
    BuildList.where(:new_core => true).
      where(:status => [
        BuildServer::SUCCESS,
        BuildList::FAILED_PUBLISH,
        BuildList::BUILD_PUBLISHED,
        BuildList::BUILD_PUBLISH
      ]).
      order(:id).
      find_in_batches(:batch_size => 100) do | build_lists |

        build_lists.each do | bl |
          puts "[#{Time.zone.now}] - where build_lists.id #{bl.id}"

          sha1 = (bl.results.find{ |r| r['file_name'] =~ /.*\.tar\.gz$/ } || {})['sha1']
          next unless sha1
          dir = Dir.mktmpdir('update-packages-', "#{APP_CONFIG['root_path']}")
          begin
            system "cd #{dir} && curl -L -O #{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha1}; tar -xzf #{sha1}"
            system "rm -f #{dir}/#{sha1}"

            extract_rpms_and_update_packages("#{dir}/archives/SRC_RPM", bl, 'source', token)
            extract_rpms_and_update_packages("#{dir}/archives/RPM", bl, 'binary', token)
          ensure
            # remove the directory.
            FileUtils.remove_entry_secure dir
          end
        end
    end

    say "[#{Time.zone.now}] done"
  end

  def extract_rpms_and_update_packages(dir, bl, package_type, token)
    Dir.glob("#{dir}/*.rpm") do |rpm_file|
      fullname = File.basename rpm_file
      package = bl.packages.by_package_type(package_type).find{ |p| p.fullname == fullname }
      next unless package
      
      package.sha1 = Digest::SHA1.file(rpm_file).hexdigest
      if %x[ curl #{APP_CONFIG['file_store_url']}/api/v1/file_stores.json?hash=#{package.sha1} ] == '[]'
        system "curl --user #{token}: -POST -F 'file_store[file]=@#{rpm_file}' #{APP_CONFIG['file_store_url']}/api/v1/upload"
      end
      package.save!
    end
  end

end