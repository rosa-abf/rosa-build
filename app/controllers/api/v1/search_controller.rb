class Api::V1::SearchController < Api::V1::BaseController
  def index
    authorize :search

    search    = Search.new(params[:query], current_user, paginate_params)
    types     = Search::TYPES.find{ |t| t == params[:type] } || Search::TYPES
    @results  = {}
    [types].flatten.each do |type|
      @results[type] = search.send(type)
    end
  end
end
