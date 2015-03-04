class SearchController < ApplicationController
  include PaginateHelper

  before_action :authenticate_user! unless APP_CONFIG['anonymous_access']
  # load_and_authorize_resource

  def index
    @type       = Search::TYPES.find{ |t| t == params[:type] } || Search::TYPES.first
    @query      = params[:query]
    @search     = Search.new(@query, current_ability, paginate_params)
    @collection = @search.send(@type)
  end
end
