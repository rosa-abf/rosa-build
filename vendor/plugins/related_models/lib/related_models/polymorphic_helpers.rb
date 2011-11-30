module RelatedModels
  module PolymorphicHelpers

    protected

      # Returns the parent type. A Comments class can have :task, :file, :note
      # as parent types.
      #
      def parent_type
        @parent_type
      end

      def parent_class
        parent.class if @parent_type
      end

      # Returns the parent object. They are also available with the instance
      # variable name: @task, @file, @note...
      #
      def parent
        k = params.symbolize_keys.keys
        res = nil

        symbols_for_association_chain.reverse.each do |sym|
          if k.include? resources_configuration[sym][:param]
            parent_config = resources_configuration[sym]
            res = parent_config[:parent_class].send(parent_config[:finder], params[parent_config[:param]])
            break
          end
        end
        return res
      end

      # If the polymorphic association is optional, we might not have a parent.
      #
      def parent?
        if resources_configuration[:polymorphic][:optional]
          parents_symbols.size > 1 || !@parent_type.nil?
        else
          true
        end
      end

    private

      # Maps parents_symbols to build association chain.
      #
      # If the parents_symbols find :polymorphic, it goes through the
      # params keys to see which polymorphic parent matches the given params.
      #
      # When optional is given, it does not raise errors if the polymorphic
      # params are missing.
      #
      def symbols_for_association_chain #:nodoc:
        polymorphic_config = resources_configuration[:polymorphic]
        parents_symbols.map do |symbol|
          if symbol == :polymorphic
            params_keys = params.keys

            keys = polymorphic_config[:symbols].map do |poly|
              params_keys.include?(resources_configuration[poly][:param].to_s) ? poly : nil
            end.compact

            if keys.empty?
              raise ScriptError, "Could not find param for polymorphic association. The request" <<
                                 "parameters are #{params.keys.inspect} and the polymorphic " <<
                                 "associations are #{polymorphic_config[:symbols].inspect}." unless polymorphic_config[:optional]

              nil
            else
              @parent_type = keys[-1].to_sym
							@parent_types = keys.map(&:to_sym)
            end
          else
            symbol
          end
        end.flatten.compact
      end
  end
end
