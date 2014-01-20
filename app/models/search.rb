class Search
  TYPES = ['projects', 'users', 'groups', 'platforms']

  def self.by_term_and_type(term, type, paginate_params)
    results = {}
    case type
    when 'all'
      TYPES.each{ |t| results[t] = find_collection(t, term, paginate_params) }
    when *TYPES
      results[type] = find_collection(type, term, paginate_params)
    end
    results
  end

  class << self
    protected

    def find_collection(type, term, paginate_params)
      type.classify.constantize.opened.
        search(term).
        search_order.
        paginate(paginate_params)
    end
  end
end