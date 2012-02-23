# -*- encoding : utf-8 -*-
class IssuesController < ApplicationController
  before_filter :authenticate_user!

  load_and_authorize_resource :project, :except => [:create_lable, :delete_label]
  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id, :only => [:show, :edit, :update, :destroy]
  before_filter :load_and_authorize_label, :only => [:create_label, :update_label, :destroy_label]

  autocomplete :user, :uname
  layout 'application'

  def index(status = 200)
    @is_assigned_to_me = params[:filter] == 'to_me'
    @is_all = params[:filter] == 'all'
    @status = (params[:status] if ['open', 'closed'].include? params[:status]) || 'open'
    @labels = params[:labels] || []

    @issues = @project.issues
    @issues = @issues.where(:user_id => current_user.id) if @is_assigned_to_me
    @issues = @issues.joins(:labels).where(:labels => {:name => @labels}) unless @labels == []

    if params[:search]
      @is_assigned_to_me = false
      @is_all = 'all'
      @status = 'open'
      @labels = []
      @issues = @project.issues.where('issues.title ILIKE ?', "%#{params[:search]}%")
    end
    @issues = @issues.includes(:creator, :user).order('serial_id desc').uniq.paginate :per_page => 10, :page => params[:page]
    if status == 200
      render 'index', :layout => request.format == '*/*' ? 'issues' : 'application' # maybe FIXME '*/*'?
    else
      render :status => status, :nothing => true
    end
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

  def create_label
    status = @project.labels.create(:name => params[:name], :color => params[:color]) ? 200 : 500
    index(status)
  end

  def update_label
    status = @label.update_attributes( :name => params[:name], :color => params[:color]) ? 200 : 500
    index(status)
  end

  def destroy_label
    status = (@label && @label_destroy) ? 200 : 500
    index(status)
  end

  private

  def load_and_authorize_label
    @project = Project.find(params[:project_id])
    @label = Label.find(params[:label_id]) if params[:label_id]
    authorize! :write, @project
  end
end
