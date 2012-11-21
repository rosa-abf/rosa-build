# -*- encoding : utf-8 -*-
class Api::V1::SearchController < Api::V1::BaseController
  TYPES = ['projects', 'users', 'groups', 'platforms']

  before_filter :authenticate_user! unless APP_CONFIG['anonymous_access']

  def index
    @results = {}
    @query = params[:query]
    type = params[:type] || 'all'
    case type
    when 'all'
      TYPES.each{ |t| @results[t] = find_collection(t) }
    when *TYPES
      @results[type] = find_collection(type)
    end
  end

  protected

  def find_collection(type)
    type.classify.constantize.opened.
      search(@query).
      search_order.
      paginate(paginate_params)
  end
end