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

        def sha1_of_file_store_files
          raise NotImplementedError, "You should implement this method"
        end

        def destroy_files_from_file_store
          sha1_of_file_store_files.each do |sha1|
            destroy_file_from_file_store sha1
          end
        end

        def destroy_file_from_file_store(sha1)
          token = User.system.find_by_uname('file_store').authentication_token
          uri = URI APP_CONFIG['file_store_url']
          Net::HTTP.start(uri.host, uri.port) do |http|
            begin
              req = Net::HTTP::Delete.new("/api/v1/file_stores/#{sha1}.json")
              req.basic_auth token, ''
              http.request(req)
            rescue # Dont care about it
            end
          end
        end
      end

      def self.file_exist_on_file_store?(sha1)
        begin
          resp = JSON(RestClient.get "#{APP_CONFIG['file_store_url']}/api/v1/file_stores.json", :params => {:hash => sha1})
        rescue # Dont care about it
          resp = []
        end
        if resp[0].respond_to?('[]') && resp[0]['file_name'] && resp[0]['sha1_hash']
          true
        else
          false
        end
      end

    end
  end
end
