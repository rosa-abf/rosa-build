class Git::BlobsController < Git::BaseController
  before_filter :set_path
  before_filter :set_commit_hash
  before_filter :find_tree

  def show
    @blob = @tree / @path
  end

  def blame
    @blob = @tree / @path

    @blame = Grit::Blob.blame(@git_repository.repo, @commit.id, @path)
  end

  def raw
    @blob = @tree / @path

    headers["Content-Disposition"] = %[attachment;filename="#{@blob.name}"]
    render :text => @blob.data, :content_type => @blob.mime_type
  end

  protected
    def set_path
      @path = params[:path]
    end

    def set_commit_hash
      @commit_hash = params[:commit_hash].present? ? params[:commit_hash] : nil
    end

    def find_tree
      if @commit_hash
        @tree = @git_repository.tree(@commit_hash)
        @commit = @git_repository.commits(@treeish, 1).first
      else
        @tree = @git_repository.tree(@treeish)

        @commit = @git_repository.log(@treeish, @path).first
        @commit_hash = @commit.id if @commit
      end
    end
end