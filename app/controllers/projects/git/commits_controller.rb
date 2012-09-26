# -*- encoding : utf-8 -*-
class Projects::Git::CommitsController < Projects::Git::BaseController
  def index
    if @path.present?
      @commits = @project.repo.log(@treeish, @path)
    else
      @commits, @page, @last_page = @project.paginate_commits(@treeish, :page => params[:page])
    end
  end

  def show
    @commit = @project.repo.commit(params[:id])
    respond_to do |format|
      format.html
      format.diff  { render :text => (@commit.diffs.map(&:diff).join("\n") rescue ''), :content_type => "text/plain" }
      format.patch { render :text => (@commit.to_patch rescue ''), :content_type => "text/plain" }
    end
  end
end
