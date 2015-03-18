class BuildListPolicy < ApplicationPolicy

  def show?
    record.user_id == user.id || policy(record.project).show?
  end
  alias_method :read?,       :show?
  alias_method :log?,        :show?
  alias_method :everything?, :show?
  alias_method :owned?,      :show?
  alias_method :everything?, :show?
  alias_method :list?,       :show?

  def create?
    return false unless record.project.is_package
    return false unless policy(record.project).write?
    record.build_for_platform.blank? || policy(record.build_for_platform).show?
  end
  alias_method :rerun_tests?, :create?

  def publish_into_testing?
    return false unless record.new_core?
    return false unless record.can_publish_into_testing?
    create? || ( record.save_to_platform.main? && publish? )
  end

  def publish?
    return false unless record.new_core?
    return false unless record.can_publish?
    if record.build_published?
      local_admin?(record.save_to_platform) || record.save_to_repository.members.exists?(id: user.id)
    else
      record.save_to_repository.publish_without_qa ?
        policy(record.project).write? : local_admin?(record.save_to_platform)
    end
  end

  def create_container?
    return false unless record.new_core?
    policy(record.project).write? || local_admin?(record.save_to_platform)
  end

  def reject_publish?
    record.save_to_repository.publish_without_qa ?
      policy(record.project).write? : local_admin?(record.save_to_platform)
  end

  def cancel?
    policy(record.project).write?
  end


end
