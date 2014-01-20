module RelatedModels
  extend ActiveSupport::Autoload

  autoload :ClassMethods
  autoload :BelongsToHelpers
  autoload :PolymorphicHelpers
  autoload :UrlHelpers
  autoload :Base
end

class ActionController::Base
  #include ClassMethods
  def self.is_related_controller!
    RelatedModels::Base.is_child!(self)
  end
end
