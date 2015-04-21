class ApplicationController < ActionController::Base
  include StrongParams
  include Pundit

  AIRBRAKE_IGNORE = [
    ActionController::InvalidAuthenticityToken,
    AbstractController::ActionNotFound
  ]

  protect_from_forgery

  layout :layout_by_resource

  # Hack to prevent token auth on all pages except atom feed:
  prepend_before_action -> { redirect_to(new_user_session_path) if params[:token] && params[:token].is_a?(String) && params[:format] != 'atom'}

  before_action :set_locale
  before_action -> { EventLog.current_controller = self },
                only: [:create, :destroy, :open_id, :cancel, :publish, :change_visibility] # :update
  before_action :banned?
  after_action -> { EventLog.current_controller = nil }
  after_action      :verify_authorized, unless: :devise_controller?
  skip_after_action :verify_authorized, only: %i(render_500 render_404)

  helper_method :get_owner

  unless Rails.env.development?
    rescue_from Exception, with: :render_500
    rescue_from ActiveRecord::RecordNotFound,
                # ActionController::RoutingError, # see: config/routes.rb:<last line>
                ActionController::UnknownController,
                ActionController::UnknownFormat,
                AbstractController::ActionNotFound, with: :render_404
  end

  rescue_from Pundit::NotAuthorizedError do |exception|
    redirect_to forbidden_url, alert: t("flash.exception_message")
  end

  rescue_from Grit::NoSuchPathError, with: :not_found


  def render_404
    render_error 404
  end

  protected

  # Disables access to site for banned users
  def banned?
    if user_signed_in? && current_user.access_locked?
      sign_out current_user
      flash[:error] = I18n.t('devise.failure.locked')
      redirect_to root_path
    end
  end

  # For this example, we are simply using token authentication
  # via parameters. However, anyone could use Rails's token
  # authentication features to get the token from a header.
  def authenticate_user!
    if user = find_user_by_token
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in user, store: false
    else
      super
    end
  end

  def authenticate_user
    if user = find_user_by_token
      sign_in user, store: false
    end
  end

  def find_user_by_token
    user_token = params[:authentication_token].presence
    if user_token.blank? && request.authorization.present?
      token, pass = *ActionController::HttpAuthentication::Basic::user_name_and_password(request)
      user_token  = token if pass.blank?
    end
    user = user_token && User.find_by_authentication_token(user_token.to_s)
  end

  def render_500(e)
    #check for exceptions Airbrake ignores by default and exclude them from manual Airbrake notification
    if Rails.env.production? && !AIRBRAKE_IGNORE.include?(e.class)
      notify_airbrake(e)
    end
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.inspect
    render_error 500
  end

  def render_error(status)
    respond_to do |format|
      format.json { render json: {status: status, message: t("flash.#{status}_message")}.to_json, status: status }
      format.all  { render file: "public/#{status}.html", status: status,
                           alert: t("flash.#{status}_message"), layout: false, content_type: 'text/html' }
    end
  end

  # Helper method for all controllers
  def permit_params(param_name, *accessible)
    (params[param_name] || ActionController::Parameters.new).permit(*accessible.flatten)
  end

  def set_locale
    I18n.locale = check_locale( get_user_locale ||
      (request.env['HTTP_ACCEPT_LANGUAGE'] ? request.env['HTTP_ACCEPT_LANGUAGE'][0,2].downcase : nil ))
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
      params['user_id'] && User.find(params['user_id']) ||
      params['group_id'] && Group.find(params['group_id']) || current_user
    end
  end

  def layout_by_resource
    if devise_controller?
      "sessions"
    else
      "application"
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def current_page
    params[:page] = 1 if params[:page].to_i < 1

    params[:page]
  end
end
