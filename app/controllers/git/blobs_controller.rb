# -*- encoding : utf-8 -*-
class Git::BlobsController < Git::BaseController
  before_filter :find_tree
  before_filter :find_branch
  before_filter :set_commit_hash
  before_filter :set_path_blob

  def show
    redirect_to project_repo_path(@project) and return unless @blob.present?
    if params[:raw]
      image_url = Rails.root.to_s + "/" + @path

      response.headers['Cache-Control'] = "public, max-age=#{12.hours.to_i}"
      response.headers['Content-Type'] = @blob.mime_type
      response.headers['Content-Disposition'] = 'inline'

      render(:text => open(image_url).read) and return
    end
  end

  def edit
    redirect_to project_repo_path(@project) and return unless @blob.present?
    authorize! :write, @project
  end

  def update
    redirect_to project_repo_path(@project) and return unless @blob.present?
    authorize! :write, @project
    # Here might be callbacks for notification purposes:
    # @git_repository.after_update_file do |repo, sha|
    # end

    res = @git_repository.update_file(params[:path], params[:content].gsub("\r", ''),
                                      :message => params[:message].gsub("\r", ''), :actor => current_user, :head => @treeish)
    if res
      flash[:notice] = t("flash.blob.successfully_updated", :name => params[:path].encode_to_default)
    else
      flash[:notice] = t("flash.blob.updating_error", :name => params[:path].encode_to_default)
    end
    redirect_to :action => :show
  end

  def blame
    @blame = Grit::Blob.blame(@git_repository.repo, @commit.try(:id), @path)
  end

  def raw
    redirect_to project_repo_path(@project) and return unless @blob.present?
    headers["Content-Disposition"] = %[attachment;filename="#{@blob.name}"]
    render :text => @blob.data, :content_type => @blob.mime_type
  end

  protected
    def find_branch
      @branch = @project.branch(@treeish)
    end

    def set_path_blob
      @path = params[:path]
      @unenc_path = @path.dup
      @path.force_encoding(Encoding::ASCII_8BIT)
      puts @path.inspect
      @blob = @tree / @path
      puts @blob.inspect
    end

    def set_commit_hash
      @commit_hash = params[:commit_hash].present? ? params[:commit_hash] : nil
    end

    def find_tree
      if @commit_hash
        puts "1"
        @tree = @git_repository.tree(@commit_hash)
        @commit = @git_repository.commits(@treeish, 1).first
      else
        puts "2"
        @tree = @git_repository.tree(@treeish)
        @commit = @git_repository.log(@treeish, @path, :max_count => 1).first # TODO WTF nil ?
      end
      puts @tree.inspect
      puts @commit.inspect
    end
end
