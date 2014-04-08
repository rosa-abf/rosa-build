class Projects::Git::BaseController < Projects::BaseController
  before_filter :authenticate_user!
  if APP_CONFIG['anonymous_access']
    skip_before_filter :authenticate_user!, only: %i(show index blame raw archive diff tags branches)
    before_filter :authenticate_user,       only: %i(show index blame raw archive diff tags branches)
  end

  load_and_authorize_resource :project
  before_filter :set_treeish_and_path
  before_filter :set_branch_and_tree

  protected

  def set_treeish_and_path
    @treeish, @path = params[:treeish].presence || @project.default_head, params[:path]
  end

  def set_branch_and_tree
    @branch = @project.repo.branches.detect{|b| b.name == @treeish}
    @tree = @project.repo.tree(@treeish)
    # raise Grit::NoSuchPathError if @tree.blobs.blank?
  end
end
