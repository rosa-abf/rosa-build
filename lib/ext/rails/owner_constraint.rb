# -*- encoding : utf-8 -*-
class OwnerConstraint
  def initialize(class_name, bang = false)
    @class_name = class_name
    @finder = 'find_by_insensitive_uname'
    @finder << '!' if bang
  end

  def matches?(request)
    @class_name.send(@finder, request.params[:owner_name]).present?
  end
end
