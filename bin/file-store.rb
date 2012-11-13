#!/usr/bin/env ruby
require 'json'
require 'rest-client'

abf_yml, new_sources = '.abf.yml', []
old_sources = if File.exist? abf_yml
                File.read(abf_yml).split("\n").reject {|line| line =~ /sources/}
              else
                []
              end
#MAX_SIZE = 2 * 1024 * 1024 # 2.megabytes
url = 'http://file-store.rosalinux.ru/api/v1/file_stores.json'
#url = 'http://localhost:3001/api/v1/file_stores.json'
rclient = RestClient::Resource.new(url, :user => ARGF.argv[0]) # user auth token

Dir.glob("*.{tar\.bz2,tar\.gz,bz2,rar,gz,tar,tbz2,tgz,zip,Z,7z,tar\.xz}").uniq.sort.each do |file|
  begin
    #next if File.size(file) < MAX_SIZE

    sha1 = Digest::SHA1.file(file).hexdigest
    resp = JSON(RestClient.get url, :params => {:hash => sha1})
    if resp[0].respond_to?('[]') && resp[0]['file_name'] && resp[0]['sha1_hash']
      # file already exists at file-store
      new_sources << "  \"#{file}\": #{sha1}"
      FileUtils.rm_rf file
      puts " file \"#{file}\" already exists in the file-store"
    elsif resp == []
      # try to put file at file-store
      resp = JSON(rclient.post :file_store => {:file => File.new(file, 'rb')})
      unless resp['sha1_hash'].nil?
        new_sources << "  \"#{file}\": #{sha1}"
        FileUtils.rm_rf file
         p " upload file \"#{file}\" to the file-store"
      else
        p " !Failed to upload file \"#{file}\" to the file-store!"
      end
    else
      raise "Response unknown!\n #{resp}"
    end

  #rescue => e
  #  e.response
  end
end
sources = (old_sources | new_sources)
unless new_sources.empty?
  File.open(abf_yml, 'w') do |abf|
    abf.puts 'sources:'
    (old_sources | new_sources).sort.each {|line| abf.puts line}
  end
end
