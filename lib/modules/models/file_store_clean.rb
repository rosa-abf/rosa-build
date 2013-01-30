# -*- encoding : utf-8 -*-
module Modules
  module Models
    module FileStoreClean
      extend ActiveSupport::Concern

      included do
        def destroy
          destroy_files_from_file_store if Rails.env.production?
          super
        end
        later :destroy, :queue => :clone_build

        def destroy_files_from_file_store
          files = []
          self.results.each {|r| files << r['sha1'] if r['sha1'].present?}
          if self.respond_to? :packages
            self.packages.each {|pk| files << pk.sha1 if pk.sha1.present?}
          end
          if files.count > 0
            token = User.system.find_by_uname('file_store').authentication_token
            uri = URI APP_CONFIG['file_store_url']
            Net::HTTP.start(uri.host, uri.port) do |http|
              files.each do |sha1|
                begin
                  req = Net::HTTP::Delete.new("/api/v1/file_stores/#{sha1}.json")
                  req.basic_auth token, ''
                  http.request(req)
                rescue # Dont care about it
                end
              end
            end
          end
        end
      end
    end
  end
end
