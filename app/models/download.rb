class Download < ActiveRecord::Base
  PREV_LOG_FILE = "#{ APP_CONFIG['nginx_log'] }.0"

  default_scope order(:name)

  class << self
    def rotate_nginx_log
      system("sudo mv #{ APP_CONFIG['nginx_log'] } #{ APP_CONFIG['nginx_log'] }.0")
      system("sudo /etc/init.d/nginx reload")
    end

    def parse_nginx_log
      File.open(PREV_LOG_FILE) do |log|
        while (line = log.gets)
          if package = line.match( /GET \/.+\/([\w\d-]+)-([\d.]+)-((\d+mdv[\d.]+)|([\d\w]+-mdv[\d.]+))\.([\w\d]+)\.rpm/ )
            increase(
              :name => package[1],
              :version => package[2],
              :distro => package[3].sub(/-/, ''),
              :platform => package[6]
            )
          end
        end
      end
    end

    def parse_and_remove_nginx_log
      parse_nginx_log
      system("sudo rm -f #{PREV_LOG_FILE}")
    end

    def increase(opts={})
      download = find_or_initialize_by_name_and_version_and_platform_and_distro(opts)
      download.counter += 1
      download.save
    end
  end
end
