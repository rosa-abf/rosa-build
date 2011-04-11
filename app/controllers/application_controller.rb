class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout_by_resource

  protected
    def layout_by_resource
      if devise_controller?
        "sessions"
      else
        "application"
      end
    end

    def authenticate_by_ip!
      if request.remote_ip != APP_CONFIG['auth_by_ip']
        render :nothing => true, :status => 403
      end
    end
end
