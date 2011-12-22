class IssuesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_project, :except => [:destroy]
  before_filter :find_and_authorize_by_serial_id, :only => [:show, :edit]
  before_filter :set_issue_stub, :only => [:new, :create]

  load_and_authorize_resource :except => [:show, :edit, :index]
  authorize_resource :project, :only => [:index]
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

  def edit
    @user_id = @issue.user_id
    @user_uname = @issue.user.uname
  end

  def update
    @user_id = params[:user_id]
    @user_uname = params[:user_uname]

    if @issue.update_attributes( params[:issue].merge({:user_id => @user_id}) )
      flash[:notice] = I18n.t("flash.issue.saved")
      redirect_to show_issue_path(@project, @issue.serial_id)
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

  def find_and_authorize_by_serial_id
    @issue = @project.issues.where(:serial_id => params[:serial_id])[0]
    authorize! params[:action].to_sym, @issue
  end

  def set_issue_stub
    @issue = Issue.new(:project => @project)
  end
end
