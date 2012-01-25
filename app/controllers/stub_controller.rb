class StubController < AbstractController::Base
  include AbstractController::Rendering
  include AbstractController::Layouts
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  include ActionController::UrlWriter

  # Uncomment if you want to use helpers 
  # defined in ApplicationHelper in your views
  # helper ApplicationHelper

  # Make sure your controller can find views
  self.view_paths = "app/views"

  # You can define custom helper methods to be used in views here
  # helper_method :current_admin
  # def current_admin; nil; end

  def partial_to_string(partial_name, locals)
    render_to_string(partial_name,  :locals => locals)
  end

end
