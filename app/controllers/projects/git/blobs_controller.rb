# -*- encoding : utf-8 -*-
class Projects::Git::BlobsController < Projects::Git::BaseController
  before_filter :find_tree
  before_filter :find_branch
  before_filter :set_path_blob

  def show
    redirect_to project_path(@project) and return unless @blob.present?
    if params[:raw]
      response.headers['Cache-Control'] = "public, max-age=#{12.hours.to_i}"
      response.headers['Content-Type'] = @blob.mime_type
      response.headers['Content-Disposition'] = 'inline'
      render(:text => @blob.data) and return
    end
  end

  def edit
    redirect_to project_path(@project) and return unless @blob.present?
    authorize! :write, @project
  end

  def update
    redirect_to project_path(@project) and return unless @blob.present?
    authorize! :write, @project
    # Here might be callbacks for notification purposes:
    # @git_repository.after_update_file do |repo, sha|
    # end

    res = @git_repository.update_file(params[:path], params[:content].gsub("\r", ''),
                                      :message => params[:message].gsub("\r", ''), :actor => current_user, :head => @treeish)
    if res
      flash[:notice] = t("flash.blob.successfully_updated", :name => params[:path])
    else
      flash[:notice] = t("flash.blob.updating_error", :name => params[:path])
    end
    redirect_to :action => :show
  end

  def blame
    @blame = Grit::Blob.blame(@git_repository.repo, @commit.id, @path)
  end

  def raw
    redirect_to project_path(@project) and return unless @blob.present?
    headers["Content-Disposition"] = %[attachment;filename="#{@blob.name}"]
    render :text => @blob.data, :content_type => @blob.mime_type
  end

  protected

  def find_branch
    @branch = @project.branch(@treeish)
  end

  def set_path_blob
    @path = params[:path]
    @blob = @tree / @path
    @commit = @git_repository.log(@treeish, @path, :max_count => 1).first
  end

  def find_tree
    @tree = @git_repository.tree(@treeish)
  end
end
