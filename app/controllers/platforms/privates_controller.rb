class Platforms::PrivatesController < Platforms::BaseController
	require 'digest/sha2'

	before_filter :find_platform
	before_filter :authenticate

	def show
		file_name = "#{APP_CONFIG['root_path']}/platforms/#{params[:platform_name]}/#{params[:file_path]}"

		if File.directory?(file_name) || !File.exists?(file_name)
			 render file: "#{Rails.root}/public/404.html", layout: false, status: 404
		else
			send_file file_name
		end
	end

	protected

	def authenticate
	  authenticate_or_request_with_http_basic do |username, password|
	  	PrivateUser.exists?(
	  		login: username,
	  		password: Digest::SHA2.new.hexdigest(password),
	  		platform_id: @platform.try(:id)
	  	)
		end
	end

	def find_platform
		@platform = Platform.find_by_name(params[:platform_name])
	end
end
