class SearchPolicy < ApplicationPolicy

  def index?
    APP_CONFIG['anonymous_access'] || !user.guest?
  end

end
