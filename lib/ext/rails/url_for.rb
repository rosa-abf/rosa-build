module ActionDispatch
  module Routing
    module UrlFor
      def url_for_with_defaults(options = nil)
        if options.kind_of?(Hash)
          if project = options[:_positional_args].try(:first) and project.is_a?(Project) # for project routes
            options[:_positional_args].unshift(project.owner) # add owner to URL for correct generation
          end
        end
        url_for_without_defaults(options)
      end
      alias_method_chain :url_for, :defaults
    end
  end
end
