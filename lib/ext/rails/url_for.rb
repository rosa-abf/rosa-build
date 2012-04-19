# -*- encoding : utf-8 -*-
module ActionDispatch
  module Routing
    module UrlFor
      def url_for_with_defaults(options = nil)
        # raise options.inspect
        if options.kind_of?(Hash)
          # if options[:controller] == 'projects' and options[:action] == 'show' and post = options[:_positional_args].try(:first) and post.blog
          if project = options[:_positional_args].try(:first) and project.is_a?(Project)
            options[:_positional_args].unshift(project.owner)
            # options[:use_route] = 'blog_post'
          end
        end
        url_for_without_defaults(options)
      end
      alias_method_chain :url_for, :defaults
    end
  end
end
