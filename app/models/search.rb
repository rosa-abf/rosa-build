class Search
  TYPES = ['projects', 'users', 'groups', 'platforms']

  def self.by_term_and_type(term, type, ability, paginate_params)
    results = {}
    case type
    when 'all'
      TYPES.each{ |t| results[t] = find_collection(t, term, ability, paginate_params) }
    when *TYPES
      results[type] = find_collection(type, term, ability, paginate_params)
    end
    results
  end

  class << self
    protected

    def find_collection(type, term, ability, paginate_params)
      scope = if type == 'users'
                User.opened
              else
                type.classify.constantize.accessible_by(ability, :read)
              end
      scope.search(term).
            search_order.
            paginate(paginate_params)
    end
  end
end