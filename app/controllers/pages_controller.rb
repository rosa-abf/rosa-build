class PagesController < ApplicationController

  def tour_inside
    @entries = case params[:id]
                      when 'builds'
                        %w(repo builds monitoring)
                      when 'sources'
                        %w(source history annotation edit)
                      when 'projects'
                        %w(control git tracker)
                      end
    render "pages/tour/tour-inside"
  end

  def forbidden
  end

  def tos
  end

end
