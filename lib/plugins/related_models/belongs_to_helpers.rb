module RelatedModels
  module BelongsToHelpers
    protected
      def parent?
        true
      end

      def parent
        @parent ||= find_parent
      end

      def parent_type
        parent.class.name.underscore.to_sym
      end

    private

      def symbols_for_association_chain
        parents_symbols.compact
      end

      def find_parent
        k = params.symbolize_keys.keys
        res = nil

        symbols_for_association_chain.reverse.each do |sym|
          if k.include? resources_configuration[sym][:param]
            parent_config = resources_configuration[sym]
            res = parent_config[:parent_class].send(parent_config[:finder], params[parent_config[:param]])
            break
          end
        end
        unless res
          raise "Couldn't find parent"
        end
        return res
      end
  end
end
