# coding: UTF-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout_by_resource

  before_filter lambda { EventLog.current_controller = self },
                :only => [:create, :destroy, :open_id, :auto_build, :cancel, :publish, :change_visibility] # :update
  after_filter lambda { EventLog.current_controller = nil }

  helper_method :get_owner
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to forbidden_url, :alert => t('flash.exception_message')#:alert => exception.message
  end
  
  protected
    def get_owner
#      params['user_id'] && User.find_by_id(params['user_id']) ||
#      params['group_id'] && Group.find_by_id(params['group_id']) || current_user
      if self.class.method_defined? :parent
        if parent and (parent.is_a? User or parent.is_a? Group)
          return parent
        else
         return current_user
        end
      else
        params['user_id'] && User.find_by_id(params['user_id']) ||
        params['group_id'] && Group.find_by_id(params['group_id']) || current_user
      end
    end

    def layout_by_resource
      if devise_controller?
        "sessions"
      else
        "application"
      end
    end
end
