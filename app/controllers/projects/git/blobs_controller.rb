class Projects::Git::BlobsController < Projects::Git::BaseController
  before_action :set_blob
  before_action -> {authorize @project, :write? }, only: [:edit, :update]

  def show
  end

  def edit
  end

  def update
    if @project.update_file(params[:path], params[:content].gsub("\r", ''),
                            message: params[:message].gsub("\r", ''), actor: current_user, head: @treeish)
      flash[:notice] = t("flash.blob.successfully_updated", name: params[:path])
    else
      flash[:notice] = t("flash.blob.updating_error", name: params[:path])
    end
    redirect_to action: :show
  end

  def blame
    @blame = Grit::Blob.blame(@project.repo, @commit.id, @path)
  end

  def raw
    repo = Grit::GitRuby::Repository.new(@project.repo.path)
    raw = repo.get_raw_object_by_sha1(@blob.id)
    send_data raw.content, type: @blob.content_type, disposition: @blob.disposition
  end

  protected

  def set_blob
    @blob = @tree / @path or raise Grit::NoSuchPathError
    redirect_to tree_path(@project, treeish: @treeish, path: @path) if @blob.is_a? Grit::Tree
    @commit = @project.repo.log(@treeish, @path, max_count: 1).first
  end
end
