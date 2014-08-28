class Api::V1::SearchController < Api::V1::BaseController
  before_filter :authenticate_user! unless APP_CONFIG['anonymous_access']

  def index
    @results = Search.by_term_and_type(
      params[:query],
      (params[:type] || 'all'),
      paginate_params
    )
    respond_to do |format|
      format.json
    end
  end
end