class PagesController < ApplicationController
  # before_filter :authenticate_user!, :except => [:show, :main, :forbidden]
  # load_and_authorize_resource

  def root
    render 'pages/tour/abf-tour-project-description-1', :layout => 'tour'
  end

  def tour_inside
    @entries = case params[:id]
                      when 'builds'
                        %w(repo builds monitoring)
                      when 'sources'
                        %w(source history annotation edit)
                      when 'projects'
                        %w(control git tracker)
                      end
    render "pages/tour/tour-inside", :layout => 'tour'
  end

  def forbidden
  end

  def tos
  end

end
