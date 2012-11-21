# -*- encoding : utf-8 -*-
class SearchController < ApplicationController
  TYPES = ['projects', 'users', 'groups', 'platforms']

  before_filter :authenticate_user! unless APP_CONFIG['anonymous_access']
  # load_and_authorize_resource

  def index
    @type = params[:type] || 'all'
    @query = params[:query]
    case @type
    when 'all'
      TYPES.each{ |t| find_collection(t) }
    when *TYPES
      find_collection(@type)
    end
  end

  protected

  def find_collection(type)
    var = :"@#{type}"
    instance_variable_set var, type.classify.constantize.opened.search(@query).search_order.paginate(:page => params[:page]) unless instance_variable_defined?(var)
  end
end
