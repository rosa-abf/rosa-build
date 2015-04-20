class Projects::Git::BaseController < Projects::BaseController
  before_action :authenticate_user!
  if APP_CONFIG['anonymous_access']
    skip_before_action :authenticate_user!, only: %i(show index blame raw archive diff tags branches)
    before_action :authenticate_user,       only: %i(show index blame raw archive diff tags branches)
  end

  before_action :set_treeish_and_path
  before_action :set_branch_and_tree

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
