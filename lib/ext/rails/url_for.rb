module ActionDispatch
  module Routing
    module UrlFor
      def url_for_with_defaults(options = nil)
        if options.kind_of?(Hash)
          if project = options[:owner_name] and project.is_a?(Project) # for project routes
            # set the correct owner and name
            options[:owner_name], options[:project_name] = project.owner, project
          end
        end
        url_for_without_defaults(options)
      end
      alias_method_chain :url_for, :defaults
    end
  end
end
