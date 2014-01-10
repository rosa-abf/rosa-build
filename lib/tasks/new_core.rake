namespace :new_core do

  desc 'Extracts all rpms from BuildList container and updates BuildList::Package#sha1 field'
  task :update_packages => :environment do
    say "[#{Time.zone.now}] Starting to extract rpms..."

    token = User.find_by_uname('rosa_system').authentication_token
    BuildList.where(:new_core => true).
      where(:status => [
        BuildList::SUCCESS,
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
            `sudo rm -rf #{dir}`
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