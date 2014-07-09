class Projects::Git::CommitsController < Projects::Git::BaseController
  layout 'bootstrap', only: [:index]

  def index
    if @path.present?
      @commits = @project.repo.log(@treeish, @path)
    else
      @commits, @page, @last_page = @project.paginate_commits(@treeish, page: params[:page])
    end
  end

  def show
    @commit = @commentable = @project.repo.commit(params[:id]) || raise(ActiveRecord::RecordNotFound)
    @comments = Comment.for_commit(@commit)

    respond_to do |format|
      format.html
      format.diff  { render text: (@commit.diffs.map(&:diff).join("\n") rescue ''), content_type: "text/plain" }
      format.patch { render text: (@commit.to_patch rescue ''), content_type: "text/plain" }
    end
  end

  def diff
    res = params[:diff].split(/\A(.*)\.\.\.(.*)\z/).select {|e| e.present?}
    if res[1].present?
      params1 = res[0]
      params2 = res[1] == 'HEAD' ? @project.default_branch : res.last
    else # get only one parameter
      params1 = @project.default_branch
      params2 = res.first
    end
    params1.sub! 'HEAD', @project.default_branch
    params2.sub! 'HEAD', @project.default_branch

    ref1 = if @project.repo.branches_and_tags.include? params1
             @project.repo.commits(params1).first
           else
             params1 # possible commit hash
           end
    @commit1 = @project.repo.commit(ref1) || raise(ActiveRecord::RecordNotFound)

    ref = if @project.repo.branches_and_tags.include? params2
            @project.repo.commits(params2).first
          else
            params2 # possible commit hash
          end
    @commit = @project.repo.commit(ref) || raise(ActiveRecord::RecordNotFound)
    @common_ancestor = @project.repo.commit(@project.repo.git.merge_base({}, @commit1, @commit)) || @commit1
    @stats = @project.repo.diff_stats @commit1.id, @commit.id
  end
end
