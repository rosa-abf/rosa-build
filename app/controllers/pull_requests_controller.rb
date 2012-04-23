# -*- encoding : utf-8 -*-
class PullRequestsController < ApplicationController
  before_filter :authenticate_user!
  load_resource :project
  load_and_authorize_resource :pull_request, :through => :project, :find_by => :serial_id

  def index(status = 200)
  end

  def new
    @base = @project.default_branch
    @head = params[:treeish].presence || @project.default_branch
  end

  def create
  end

  def update
  end

end
