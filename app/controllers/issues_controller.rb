# -*- encoding : utf-8 -*-
class IssuesController < ApplicationController
  NON_RESTFUL_ACTION = [:create_label, :update_label, :destroy_label, :search_collaborators]
  before_filter :authenticate_user!

  load_and_authorize_resource :project, :except => NON_RESTFUL_ACTION
  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id, :only => [:show, :edit, :update, :destroy]
  before_filter :load_and_authorize_label, :only => NON_RESTFUL_ACTION

  layout 'application'

  def index(status = 200)
    logger.debug "!!!!!!!!!!!!!!!!!!"
    logger.debug "request format is #{request.format}"
    @is_assigned_to_me = params[:filter] == 'to_me'
    @status = params[:status] == 'closed' ? 'closed' : 'open'
    @labels = params[:labels] || []
    @issues = @project.issues
    @issues = @issues.where(:user_id => current_user.id) if @is_assigned_to_me
    @issues = @issues.joins(:labels).where(:labels => {:name => @labels}) unless @labels == []

    if params[:search_issue]
      @issues = @issues.where('issues.title ILIKE ?', "%#{params[:search_issue].mb_chars.downcase}%")
    end
    @opened_issues = @issues.opened.count
    @closed_issues = @issues.closed.count
    @issues = @issues.where(:status => @status)


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
    @issue.creator_id = current_user.id
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

  def update
    if status = params[:issue][:status]
      action = 'issues/_status'
      @issue.set_close(current_user) if status == 'closed'
      @issue.set_open if status == 'open'
      status = 200 if @issue.save
      render action, :status => (status || 500), :layout => false
    else
      @issue.title = params[:issue][:title]
      @issue.body = params[:issue][:body]
      status = 200 if @issue.save
      render :nothing => true, :status => (status || 500), :layout => false
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

  def search_collaborators
    search = "%#{params[:search_user]}%"
    users = User.joins(:groups => :projects).where(:projects => {:id => @project.id}).where("users.uname ILIKE ?", search)
    users2 = @project.collaborators.where("users.uname ILIKE ?", search)
    @users = (users + users2).uniq.sort {|x,y| x.uname <=> y.uname}.first(10)
    render 'issues/_search_collaborators', :layout => false
  end

  def search_labels
    @labels = @project.labels.where("labels.name ILIKE ?", "%#{params[:search_labels]}%").order('labels.name').limit(10)
    render 'issues/_search_labels', :layout => false
  end

  private

  def load_and_authorize_label
    @project = Project.find(params[:project_id])
    @label = Label.find(params[:label_id]) if params[:label_id]
    authorize! :write, @project
  end
end
