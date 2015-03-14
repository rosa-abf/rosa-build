class ProjectPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    return true if record.public?
  end

  # for grack
  def write?
    local_writer?
  end

  def read?
    show?
  end

  def archive?
    show?
  end

  def fork?
    show?
  end

end
