# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# Block admin access to non-admin-users.
ActiveAdmin::BaseController.class_eval do # FIXME upgrade видимо изменилась последовательность инициализации и этот код внутри active_admin выдает ошибку 'undefined method'
  skip_after_action :verify_authorized

  # include ActionController::Caching::Sweeping
  protected
  def check_admin_role
    raise ActiveRecord::RecordNotFound unless current_user.admin?
  end
end

