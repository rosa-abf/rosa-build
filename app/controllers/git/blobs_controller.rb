class Git::BlobsController < Git::BaseController
  before_filter :set_path
  before_filter :set_treeish
  before_filter :set_commit_hash

  def show
    if @commit_hash
      @tree = @git_repository.tree(@commit_hash)
      @commit = @git_repository.commits(@treeish, 1).first
    else
      @tree = @git_repository.tree(@treeish)

      @commit = @git_repository.log(@treeish, @path).first
      @commit_hash = @commit.id if @commit
    end

    @blob = @tree / @path
  end

  def blame
    if @commit_hash
      @tree = @git_repository.tree(@commit_hash)
      @commit = @git_repository.commits(@commit_hash).first
    else
      @tree = @git_repository.tree(@treeish)
      @commit = @git_repository.repo.log(@treeish, @path).first
    end

    @blob = @tree / @path

    @blame = Grit::Blob.blame(@git_repository.repo, @commit.id, @path)
  end

  def raw
    if @commit_hash
      @tree = @git_repository.tree(@commit_hash)
    else
      @tree = @git_repository.tree(@treeish)
      @commit_hash = @git_repository.repo.log(@treeish, @path).first.id
    end

    @blob = @tree / @path

    headers["Content-Disposition"] = %[attachment;filename="#{@blob.name}"]
    render :text => @blob.data, :content_type => @blob.mime_type
  end

  protected
    def set_path
      @path = params[:path]
    end

    def set_treeish
      @treeish = params[:treeish] ? params[:treeish] : "master"
    end

    def set_commit_hash
      @commit_hash = params[:commit_hash].present? ? params[:commit_hash] : nil
    end
end