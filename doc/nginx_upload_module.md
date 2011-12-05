===================== Nginx compile

rvmsudo passenger-install-nginx-module --nginx-source-dir=/opt/src/nginx-1.0.10 --extra-configure-flags=--add-module=/opt/src/nginx_upload_module-2.2.0 

===================== Nginx config

server {
  listen 80;
  server_name rosa-build.local www.rosa-build.local;
  # server_name rosa-build.rosalab.ru;
  # server_name npp-build.rosalab.ru;

  client_max_body_size 1G;
  root /Users/pasha/Sites/rosa-build/public;

	# Match this location for the upload module
  location ~* ^\/platforms\/([0-9]+)\/products/([0-9]+)$ {
    error_page  405 = @rails; # fallback to rails

    # pass request body to rails
    # upload_pass @rails;
    upload_pass @upload;

    # Store files to this directory
    # The directory is hashed, subdirectories 0 1 2 3 4 5 6 7 8 9 should exist
    # i.e. make sure to create /u/apps/bugle/shared/uploads_tmp/0 /u/apps/bugle/shared/uploads_tmp/1 etc.
    # upload_store /u/apps/bugle/shared/uploads_tmp 1;
    upload_store /tmp; # /srv/rosa_build/shared/tmp

    # set permissions on the uploaded files
    upload_store_access user:rw group:rw all:r;

    # Set specified fields in request body this puts the original filename, new path+filename and content type in the requests params
    upload_set_form_field $upload_field_name[name] "$upload_file_name";
      upload_set_form_field $upload_field_name[content_type] "$upload_content_type";
      upload_set_form_field $upload_field_name[path] "$upload_tmp_path";
      upload_aggregate_form_field $upload_field_name[size] "$upload_file_size";

    upload_pass_form_field "^.+$"; # "^theme_id$|^blog_id$|^authenticity_token$|^format$"
    upload_cleanup 400 404 499 500-505;
  }

	location / {
		try_files		/system/maintenance.html $uri	$uri/index.html	$uri.html	@rails;
	}

	location @rails {
    passenger_enabled on;
    passenger_use_global_queue on;
		# rails_env production;
    # proxy_pass   http://localhost:8080;
    # proxy_pass   http://unix:/tmp/rosa_build.sock;
    # proxy_redirect   http://localhost/    http://$host:$server_port/;
    # proxy_read_timeout 1200;
	}

  location @upload {
    proxy_pass   http://localhost:8080;
    # proxy_pass   http://unix:/tmp/rosa_build.sock;
    # proxy_redirect   http://localhost/    http://$host:$server_port/;
	}
}
