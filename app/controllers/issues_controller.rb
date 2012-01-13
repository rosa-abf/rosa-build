class IssuesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_project
  before_filter :find_issue_by_serial_id, :only => [:show, :edit, :update, :destroy]

  load_and_authorize_resource :project
  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id

  autocomplete :user, :uname

  def index
    @issues = @project.issues
    case params[:status]
    when 'open'
      @issues = @issues.where(:status => 'open')
    when 'closed'
      @issues = @issues.where(:status => 'closed')
    end
    @issues = @issues.paginate :per_page => 10, :page => params[:page]
  end

  def new
    @issue = Issue.new(:project => @project)
  end

  def create
    @user_id = params[:user_id]
    @user_uname = params[:user_uname]

    @issue = Issue.new(params[:issue])
    @issue.user_id = @user_id
    @issue.project_id = @project.id

    if @issue.save
      @issue.subscribe_creator(current_user.id)

      flash[:notice] = I18n.t("flash.issue.saved")
      redirect_to project_issues_path(@project)
    else
      flash[:error] = I18n.t("flash.issue.save_error")
      render :action => :new
    end
  end

  def edit
    @user_id = @issue.user_id
    @user_uname = @issue.assign_uname
  end

  def update
    @user_id = params[:user_id].blank? ? @issue.user_id : params[:user_id]
    @user_uname = params[:user_uname].blank? ? @issue.assign_uname : params[:user_uname]

    if @issue.update_attributes( params[:issue].merge({:user_id => @user_id}) )
      flash[:notice] = I18n.t("flash.issue.saved")
      redirect_to [@project, @issue]
    else
      flash[:error] = I18n.t("flash.issue.save_error")
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

  def find_issue_by_serial_id
    @issue = @project.issues.find_by_serial_id!(params[:id])
  end
end
