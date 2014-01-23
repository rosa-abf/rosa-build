module RelatedModels
  class Base < ::ApplicationController
    def self.is_child!(base)
      base.class_eval do
#        include InheritedResources::Actions
#        include InheritedResources::BaseHelpers
        extend  RelatedModels::ClassMethods
        extend  RelatedModels::UrlHelpers

        helper_method :parent_url, :parent_path

        self.class_attribute :parents_symbols, :resources_configuration, instance_writer: false

        self.parents_symbols ||= []
        self.resources_configuration ||= {}

        protected :parents_symbols, :resources_configuration, :parents_symbols?, :resources_configuration?
      end
    end

    is_child!(self)
  end
end
