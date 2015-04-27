module StrongParams
  extend ActiveSupport::Concern

  protected

  def permit_params(param_name, *accessible)
    [param_name].flatten.inject(params.dup) do |pp, name|
      pp = pp[name] || ActionController::Parameters.new
    end.permit(*accessible.flatten)
  end
end
