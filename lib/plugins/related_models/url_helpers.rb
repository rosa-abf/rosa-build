module RelatedModels
  module UrlHelpers
    protected

      def create_resources_url_helpers!
        segment = if parents_symbols.include? :polymorphic
          :polymorphic
        else
          resources_configuration[symbols_for_association_chain.first][:route_name]
        end

        unless parent.nil?
          class_eval <<-URL_HELPERS, __FILE__, __LINE__
            protected
              def parent_path(*given_args)
                given_options = given_args.extract_options!
                #{segment}_path(parent, given_options)
              end

              def parent_url(*given_args)
                given_options = given_args.extract_options!
                #{segment}_url(parent, given_options)
              end
          URL_HELPERS
        end
      end
  end
end
