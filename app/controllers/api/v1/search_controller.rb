class Api::V1::SearchController < Api::V1::BaseController
  before_action :authenticate_user! unless APP_CONFIG['anonymous_access']

  def index
    search    = Search.new(params[:query], current_ability, paginate_params)
    types     = Search::TYPES.find{ |t| t == params[:type] } || Search::TYPES
    @results  = {}
    [types].flatten.each do |type|
      @results[type] = search.send(type)
    end

    respond_to :json
  end
end