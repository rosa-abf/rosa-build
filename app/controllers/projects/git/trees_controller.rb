# -*- encoding : utf-8 -*-
class Projects::Git::TreesController < Projects::Git::BaseController
  before_filter lambda{redirect_to @project if params[:treeish] == @project.default_branch and params[:path].blank?}, :only => :show
  skip_before_filter :set_branch_and_tree, :set_treeish_and_path, :only => :archive
  before_filter lambda { raise Grit::NoSuchPathError if params[:treeish] != @branch.try(:name) }, :only => [:branch, :destroy]

  skip_authorize_resource :project,                       :only => [:destroy, :restore_branch, :create]
  before_filter lambda { authorize!(:write, @project) },  :only => [:destroy, :restore_branch, :create]

  def show
    render('empty') and return if @project.is_empty?
    @tree = @tree / @path if @path.present?
    @commit = @branch.present? ? @branch.commit() : @project.repo.log(@treeish, @path, :max_count => 1).first
    raise Grit::NoSuchPathError unless @commit
  end

  def archive
    format, @treeish = params[:format], params[:treeish]
    if (@treeish =~ /^#{@project.name}-/) && !(@treeish =~ /[\s]+/) && (format =~ /^(zip|tar\.gz)$/)
      @treeish = @treeish.gsub(/^#{@project.name}-/, '')
      @commit = @project.repo.commits(@treeish, 1).first
    end
    raise Grit::NoSuchPathError unless @commit
    tag   = @project.repo.tags.find{ |t| t.name == @treeish }
    sha1  = @project.get_project_tag_sha1(tag, format) if tag
    if sha1
      redirect_to "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha1}"
    else
      archive = @project.archive_by_treeish_and_format @treeish, format
      send_file archive[:path], :disposition => 'attachment', :type => "application/#{format == 'zip' ? 'zip' : 'x-tar-gz'}", :filename => archive[:fullname]
    end
  end

  def tags
  end

  def restore_branch
    status = @project.create_branch(@treeish, params[:sha], current_user) ? 200 : 422
    render :nothing => true, :status => status
  end

  def create
    status = @project.create_branch(params[:new_ref], params[:from_ref], current_user) ? 200 : 422
    render :nothing => true, :status => status
  end

  def destroy
    status = @branch && @project.delete_branch(@branch, current_user) ? 200 : 422
    render :nothing => true, :status => status
  end

  def branches
  end

end
