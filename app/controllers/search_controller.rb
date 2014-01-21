class SearchController < ApplicationController
  before_filter :authenticate_user! unless APP_CONFIG['anonymous_access']
  # load_and_authorize_resource

  def index
    @type = params[:type] || 'all'
    @query = params[:query]
    Search.by_term_and_type(
      @query,
      @type,
      {page: params[:page]}
    ).each do |k, v|
      var = :"@#{k}"
      instance_variable_set var, v unless instance_variable_defined?(var)
    end
  end
end
