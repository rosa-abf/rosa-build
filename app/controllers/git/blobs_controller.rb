class Git::BlobsController < Git::BaseController
  before_filter :set_path
  before_filter :set_commit_hash
  before_filter :find_tree

  def show
    @blob = @tree / @path

    if params[:raw]
      image_url = Rails.root.to_s + "/" + @path

      response.headers['Cache-Control'] = "public, max-age=#{12.hours.to_i}"
      response.headers['Content-Type'] = @blob.mime_type
      response.headers['Content-Disposition'] = 'inline'

      render(:text => open(image_url).read) and return
    end
  end

  def blame
    @blob = @tree / @path

    @blame = Grit::Blob.blame(@git_repository.repo, @commit.try(:id), @path)
  end

  def raw
    @blob = @tree / @path

    headers["Content-Disposition"] = %[attachment;filename="#{@blob.name}"]
    render :text => @blob.data, :content_type => @blob.mime_type
  end

  def image
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
        puts "1"
        @tree = @git_repository.tree(@commit_hash)
        @commit = @git_repository.commits(@treeish, 1).first
      else
        puts "2"
        @tree = @git_repository.tree(@treeish)
        puts @tree.name.inspect

        @commit = @git_repository.log(@treeish, @path).first # TODO WTF nil ?
      end
    end
end
