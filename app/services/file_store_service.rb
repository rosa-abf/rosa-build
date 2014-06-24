module FileStoreService
  class File

    URL = APP_CONFIG['file_store_url']

    attr_accessor :sha1, :data

    # @param [String] sha1
    # @param [Hash] data:
    # - [String] path     - path to file
    # - [String] fullname - file name
    def initialize(sha1: nil, data: {})
      @sha1, @data = sha1, data
    end

    def exist?
      resp = JSON(RestClient.get "#{URL}/api/v1/file_stores.json", params: {hash: sha1})
      if resp[0].respond_to?('[]') && resp[0]['file_name'] && resp[0]['sha1_hash']
        true
      else
        false
      end
    rescue # Dont care about it
      return false
    end

    def save
      sha1 = Digest::SHA1.hexdigest(::File.read(data[:path]))
      return sha1 if exist?

      resource  = RestClient::Resource.new("#{URL}/api/v1/upload", user: token)
      file      = ::File.new(data[:path])
      # Hook for RestClient
      # See: [RestClient::Payload#create_file_field](https://github.com/rest-client/rest-client/blob/master/lib/restclient/payload.rb#L202-L215)
      file.define_singleton_method(:original_filename) { data[:fullname] }
      resp = resource.post(file_store: { file: file })
      resp = JSON(resp)

      if resp.respond_to?(:[]) && resp['sha1_hash'].present?
        resp['sha1_hash']
      else
        nil
      end
    rescue RestClient::UnprocessableEntity => e # 422, file already exist
      return sha1
    rescue # Dont care about it
      return nil
    end

    def destroy
      uri   = URI(URL)
      Net::HTTP.start(uri.host, uri.port) do |http|
        req = Net::HTTP::Delete.new("/api/v1/file_stores/#{sha1}.json")
        req.basic_auth token, ''
        http.request(req)
      end
    rescue # Dont care about it
    end

    protected

    def token
      Rails.cache.fetch([FileStoreService::File, :token], expires_in: 10.minutes) do
        User.find_by(uname: 'file_store').authentication_token
      end
    end

  end
end