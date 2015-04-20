module StrongParams
  extend ActiveSupport::Concern

  protected

  def permit_params(param_name, *accessible)
    (params[param_name] || ActionController::Parameters.new).permit(*accessible.flatten)
  end
end
