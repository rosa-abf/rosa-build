# coding: UTF-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout_by_resource


  before_filter lambda { EventLog.current_controller = self },
                :only => [:create, :destroy, :open_id, :auto_build, :process_build, :cancel, :publish] # :update
  after_filter lambda { EventLog.current_controller = nil }

  helper_method :get_owner
  protected
    def get_owner
      params['user_id'] && User.find_by_id(params['user_id']) ||
      params['group_id'] && Group.find_by_id(params['group_id']) || current_user
    end

    def layout_by_resource
      if devise_controller?
        "sessions"
      else
        "application"
      end
    end

    def authenticate_build_service!
      if request.remote_ip != APP_CONFIG['build_service_ip']
        render :nothing => true, :status => 403
      end
    end

    def authenticate_product_builder!
      if request.remote_ip != APP_CONFIG['product_builder_ip']
        render :nothing => true, :status => 403
      end
    end
end
