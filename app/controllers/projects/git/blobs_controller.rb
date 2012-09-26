# -*- encoding : utf-8 -*-
class Projects::Git::BlobsController < Projects::Git::BaseController
  before_filter :set_blob
  before_filter lambda {authorize! :write, @project}, :only => [:edit, :update]

  def show
  end

  def edit
  end

  def update
    if @project.update_file(params[:path], params[:content].gsub("\r", ''),
                            :message => params[:message].gsub("\r", ''), :actor => current_user, :head => @treeish)
      flash[:notice] = t("flash.blob.successfully_updated", :name => params[:path])
    else
      flash[:notice] = t("flash.blob.updating_error", :name => params[:path])
    end
    redirect_to :action => :show
  end

  def blame
    @blame = Grit::Blob.blame(@project.repo, @commit.id, @path)
  end

  def raw
    send_data @blob.data, :type => @blob.content_type, :disposition => @blob.disposition
  end

  protected

  def set_blob
    @blob = @tree / @path or raise Grit::NoSuchPathError
    @commit = @project.repo.log(@treeish, @path, :max_count => 1).first
  end
end
