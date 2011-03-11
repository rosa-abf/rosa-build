class Git::CommitsController < Git::BaseController

  def index
    @branch_name = (params[:branch] ? params[:branch] : "master")
    @path = params[:path]

    @commits = @path.present? ? @git_repository.repo.log(@branch_name, @path) : @git_repository.commits(@branch_name)
  end

  def show
    @commit = @git_repository.commits(params[:id]).first

    respond_to do |format|
      format.html
      format.diff  { render :text => @commit.diffs.map{|d| d.diff}.join("\n"), :content_type => "text/plain" }
      format.patch { render :text => @commit.to_patch, :content_type => "text/plain" }
    end
  end

end