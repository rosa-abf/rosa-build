# Internal: various definitions and instance methods related to default_branch.
#
# This module gets mixed in into Project class.
module Project::DefaultBranch
  extend ActiveSupport::Concern

  include DefaultBranchable

  included do
    validate :check_default_branch

    after_update :set_new_git_head
  end

  ######################################
  #          Instance methods          #
  ######################################

  # Public: Get default branch according to owner configs.
  #
  # Returns found String branch name.
  def resolve_default_branch
    return default_branch       unless owner.is_a?(Group) && owner.default_branch.present?
    return default_branch       unless repo.branches.map(&:name).include?(owner.default_branch)
    return owner.default_branch unless default_branch.present?
    default_branch == 'master' ? owner.default_branch : default_branch
  end

  # Public: Finds branch name for platforms.
  #
  # save_to_platform   - The save Platform.
  # build_for_platform - The build Platform.
  #
  # Returns found String branch name.
  def project_version_for(save_to_platform, build_for_platform)
    if repo.commits("#{save_to_platform.default_branch}").try(:first).try(:id)
      save_to_platform.default_branch
    elsif repo.commits("#{build_for_platform.default_branch}").try(:first).try(:id)
      build_for_platform.default_branch
    else
      resolve_default_branch
    end
  end

  # Public: Finds default head.
  #
  # treeish - The String treeish.
  #
  # Returns found String head.
  def default_head(treeish = nil) # maybe need change 'head'?
    # Attention!
    # repo.commit(nil) => <Grit::Commit "b6c0f81deb17590d22fc07ba0bbd4aa700256f61">
    # repo.commit(nil.to_s) => nil
    return treeish if treeish.present? && repo.commit(treeish).present?
    if repo.branches_and_tags.map(&:name).include?(treeish || resolve_default_branch)
      treeish || resolve_default_branch
    else
      repo.branches_and_tags[0].try(:name) || resolve_default_branch
    end
  end

  protected

  # Private: Set git head.
  def set_new_git_head
    if self.default_branch_changed? && self.repo.branches.map(&:name).include?(self.default_branch)
      self.repo.git.send(:'symbolic-ref', {}, 'HEAD', "refs/heads/#{self.default_branch}")
      Project.project_aliases(self).update_all default_branch: self.default_branch
    end
  end

  # Private: Validation for checking that the default branch is exist.
  def check_default_branch
    if self.repo.branches.count > 0 && self.repo.branches.map(&:name).exclude?(self.default_branch)
      errors.add :default_branch, I18n.t('activerecord.errors.project.default_branch')
    end
  end

end
