module RelatedModels
  module ClassMethods
    protected
      def belongs_to(*symbols)
        options = symbols.extract_options!

        options.symbolize_keys!
        options.assert_valid_keys(:polymorphic, :optional, :finder)

        optional    = options.delete(:optional)
        polymorphic = options.delete(:polymorphic)
        finder      = options.delete(:finder)

        include BelongsToHelpers if self.parents_symbols.empty?

        acts_as_polymorphic! if polymorphic || optional

        raise ArgumentError, 'You have to give me at least one association name.' if symbols.empty?
        raise ArgumentError, 'You cannot define multiple associations with options: #{options.keys.inspect} to belongs to.' unless symbols.size == 1 || options.empty?

        symbols.each do |symbol|
          symbol = symbol.to_sym

          if polymorphic || optional
            self.parents_symbols << :polymorphic unless self.parents_symbols.include?(:polymorphic)
            self.resources_configuration[:polymorphic] ||= {}
            self.resources_configuration[:polymorphic][:symbols] ||= []

            self.resources_configuration[:polymorphic][:symbols] << symbol
            self.resources_configuration[:polymorphic][:optional] ||= optional
          else
            self.parents_symbols << symbol
          end

          config = self.resources_configuration[symbol] = {}

          config[:parent_class] = begin
            class_name = symbol.to_s.pluralize.classify
            class_name.constantize
          rescue NameError => e
            raise unless e.message.include?(class_name)
            nil
          end

          config[:collection_name] = symbol.to_s.pluralize.to_sym
          config[:instance_name]   = symbol
          config[:param]           = :"#{symbol}_id"
          config[:route_name]      = symbol
          config[:finder]          = finder || :find
        end

        create_resources_url_helpers!
        helper_method :parent, :parent?
      end

    private
      def acts_as_polymorphic! #:nodoc:
        unless self.parents_symbols.include?(:polymorphic)
          include PolymorphicHelpers
          helper_method :parent_type, :parent_class
        end
      end

      def inherited(base)
        super(base)
      end
  end
end
