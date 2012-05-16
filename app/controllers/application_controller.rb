# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery

  layout :layout_by_resource

  # Hack to prevent token auth on all pages except atom feed:
  prepend_before_filter lambda { redirect_to(new_user_session_path) if params[:token] && params[:format] != 'atom'}

  before_filter :set_locale
  before_filter lambda { EventLog.current_controller = self },
                :only => [:create, :destroy, :open_id, :cancel, :publish, :change_visibility] # :update
  after_filter lambda { EventLog.current_controller = nil }

  helper_method :get_owner

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to forbidden_url, :alert => t("flash.exception_message")
  end

  protected

  def set_locale
    I18n.locale = check_locale( get_user_locale ||
      request.env['HTTP_ACCEPT_LANGUAGE'] ? request.env['HTTP_ACCEPT_LANGUAGE'][0,2].downcase : nil )
  end

  def get_user_locale
    user_signed_in? ? current_user.language : nil
  end

  def check_locale(locale)
    User::LANGUAGES.include?(locale.to_s) ? locale : :en
  end

  def get_owner
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
    if devise_controller? && !(params[:controller] == 'devise/registrations' && ['edit', 'update'].include?(params[:action]))
      "sessions"
    else
      "application"
    end
  end
end
