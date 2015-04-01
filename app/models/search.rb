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
        # scope_policy(type.classify.constantize).accessible_by(ability, :show)
        "#{klass}Policy::Scope".classify.constantize.new(user, klass).show
        # policy_scope(type.classify.constantize).show
      end
    scope.search(query).
          search_order.
          paginate(paginate_params)
  end

end
