# -*- encoding : utf-8 -*-
class Platforms::MaintainersController < ApplicationController
  ET_CALLBACKS = [:assignee]
  before_filter :authenticate_user!, :except => ET_CALLBACKS
  load_and_authorize_resource :platform, :except => ET_CALLBACKS

  def index
    # Let's build a relation to query maintainers via 'build_list_packages' table
    @maintainers = BuildList::Package.maintainers.where(:platform_id => @platform).order('lower(name) ASC').includes(:project).paginate(:page => params[:page])
  end

end

