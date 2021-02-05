class RobotsController < ApplicationController
  skip_after_action :verify_authorized

  def index
    render file: 'sitemap/robots', layout: false, content_type: Mime::TEXT
  end
end
