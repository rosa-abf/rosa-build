# -*- encoding : utf-8 -*-
class PagesController < ApplicationController
  # before_filter :authenticate_user!, :except => [:show, :main, :forbidden]
  # load_and_authorize_resource

  def root
    render 'pages/tour/abf-tour-project-description-1', :layout => 'tour'
  end

  def tour_inside
    render "pages/tour/tour-inside-#{params[:id]}", :layout => 'tour'
  end

  def forbidden
  end

  def tos
  end
end
