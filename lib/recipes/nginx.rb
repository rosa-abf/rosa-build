Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :nginx do
      set :nginx_init_path, "/etc/init.d/nginx"

      desc "Generate Nginx configuration"
      task :generate_configuration, :roles => :web, :except => { :no_release => true } do
        cur_path = File.join(deploy_to, current_dir)
        nginx_config_path = "/etc/nginx/conf.d/#{application}.conf"
        config = %Q{
upstream #{application}_backend {
  server  127.0.0.1:#{unicorn_port};
}

server {
  listen  80;
  server_name	#{domain};
    root    #{cur_path}/public;

    location /downloads {
      autoindex on;
    }

    try_files $uri/index.html $uri.html $uri @myapp;

    location @myapp {
      proxy_pass          http://#{application}_backend;
      proxy_set_header    Host $host;
      proxy_set_header    X-Forwarded-For $remote_addr;
      proxy_read_timeout  300;
      proxy_send_timeout  180;
      proxy_redirect      off;
    }

    access_log    #{shared_path}/log/nginx.access.log;
    error_log     #{shared_path}/log/nginx.error.log;

    error_page 500 502 503 504 /500.html;
    location = /500.html {
      root    #{cur_path}/public;
    }
}
}
        # puts config
        puts "Write nginx config to #{nginx_config_path}"
        put config, '/tmp/nginx.conf'
        sudo "mv /tmp/nginx.conf #{nginx_config_path}", :pty => true
      end

      desc "Start nginx web server"
      task :start, :roles => :web, :except => { :no_release => true } do
        sudo "#{fetch :nginx_init_path} start"
      end

      desc "Stop nginx web server"
      task :stop, :roles => :web, :except => { :no_release => true } do
        sudo "#{fetch :nginx_init_path} stop"
      end

      desc "Restart nginx web server"
      task :restart, :roles => :web, :except => { :no_release => true } do
        sudo "#{fetch :nginx_init_path} restart"
      end

      desc "Resload nginx web server"
      task :reload, :roles => :web, :except => { :no_release => true } do
        sudo "#{fetch :nginx_init_path} reload"
      end
    end
  end
end