# RelatedModels
module RelatedModels
  autoload :ClassMethods,       'related_models/class_methods'
  autoload :BelongsToHelpers,   'related_models/belongs_to_helpers'
  autoload :PolymorphicHelpers, 'related_models/polymorphic_helpers'
  autoload :UrlHelpers,         'related_models/url_helpers'
end

class ActionController::Base
  #include ClassMethods
  def self.is_related_controller!
    RelatedModels::Base.is_child!(self)
  end
end
