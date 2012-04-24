# -*- encoding : utf-8 -*-
class OwnerConstraint
  def initialize(class_name)
    @class_name = class_name
  end

  def matches?(request)
    !!@class_name.find_by_uname(request.params[:owner_name])
  end
end
