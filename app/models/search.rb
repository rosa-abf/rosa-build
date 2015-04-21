class Search < Struct.new(:query, :user, :paginate_params)
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  TYPES = %w(projects users groups platforms)


  TYPES.each do |type|
    define_method type do
      find_collection(type)
    end
  end

  private

  def find_collection(type)
    scope =
      if type == 'users'
        User.opened
      else
        klass = type.classify.constantize
        "#{klass}Policy::Scope".constantize.new(user, klass).show
      end
    scope.search(query).
          search_order.
          paginate(paginate_params)
  end

end
