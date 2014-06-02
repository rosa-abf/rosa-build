module FileStoreClean
  extend ActiveSupport::Concern

  included do
    def destroy
      destroy_files_from_file_store if Rails.env.production?
      super
    end
    later :destroy, queue: :middle

    def sha1_of_file_store_files
      raise NotImplementedError, "You should implement this method"
    end

    def destroy_files_from_file_store(args = sha1_of_file_store_files)
      files = *args
      token = FileStoreClean.file_store_authentication_token
      uri   = URI APP_CONFIG['file_store_url']
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

    def later_destroy_files_from_file_store(args)
      destroy_files_from_file_store(args)
    end
    later :later_destroy_files_from_file_store, queue: :middle
  end

  def self.file_store_authentication_token
    User.find_by(uname: 'file_store').authentication_token
  end

  # @param [Hash] data:
  # - [String] path     - path to file
  # - [String] fullname - file name
  def self.save_file_to_file_store(data)
    sha1_hash = Digest::SHA1.hexdigest(File.read(data[:path]))
    return sha1_hash if file_exist_on_file_store?(sha1_hash)

    begin
      resource  = RestClient::Resource.new(
        "#{APP_CONFIG['file_store_url']}/api/v1/upload",
        user: file_store_authentication_token
      )

      file = File.new(data[:path])
      # Hook for RestClient
      # See: [RestClient::Payload#create_file_field](https://github.com/rest-client/rest-client/blob/master/lib/restclient/payload.rb#L202-L215)
      file.define_singleton_method(:original_filename) { data[:fullname] }
      resp = resource.post(file_store: { file: file })
      resp = JSON(resp)
    rescue RestClient::UnprocessableEntity => e # 422, file already exist
      return sha1_hash
    rescue # Dont care about it
      return nil
    end
    if resp.respond_to?(:[]) && resp['sha1_hash'].present?
      resp['sha1_hash']
    else
      nil
    end
  end

  def self.file_exist_on_file_store?(sha1)
    begin
      resp = JSON(RestClient.get "#{APP_CONFIG['file_store_url']}/api/v1/file_stores.json", params: {hash: sha1})
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
