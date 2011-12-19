class IssuesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_project
  before_filter :find_issue, :only => [:show, :edit, :update, :destroy]

  load_and_authorize_resource
  autocomplete :user, :uname

  def index
    @issues = @project.issues.paginate :per_page => 10, :page => params[:page]
  end

  def create
    @user_id = params[:user_id]
    @user_uname = params[:user_uname]

    @issue = Issue.new(params[:issue])
    @issue.user_id = @user_id
    @issue.project_id = @project.id
    if @issue.save!
      flash[:notice] = I18n.t("flash.issue.saved")
      redirect_to project_issues_path(@project)
    else
      flash[:error] = I18n.t("flash.issue.saved_error")
      render :action => :new
    end
  end

  def update
    @user_id = params[:user_id]
    @user_uname = params[:user_uname]

    if @issue.update_attributes( params[:issue].merge({:user_id => @user_id}) )
      flash[:notice] = I18n.t("flash.issue.saved")
      redirect_to @issue
    else
      flash[:error] = I18n.t("flash.issue.saved_error")
      render :action => :new
    end
  end

  def destroy
    @issue.destroy

    flash[:notice] = t("flash.issue.destroyed")
    redirect_to root_path
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_issue
    @issue = Issue.find(params[:id])
  end
end
