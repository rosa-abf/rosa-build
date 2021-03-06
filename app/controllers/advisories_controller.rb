class AdvisoriesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user! if APP_CONFIG['anonymous_access']

  def index
    authorize :advisory
    @advisories = Advisory.includes(:platforms, :projects).search(params[:q]).uniq
    @advisories_count = @advisories.count
    @advisories = @advisories.paginate(page: current_page, per_page: Advisory.per_page)
    respond_to do |format|
      format.html
      format.json
      format.atom
    end
  end

  def show
    authorize @advisory = Advisory.find_by(advisory_id: params[:id])
    @packages_info = @advisory.fetch_packages_info
  end

  def search
    authorize :advisory
    @advisory = Advisory.by_update_type(params[:bl_type]).search_by_id(params[:query]).first
    if @advisory.nil?
      render nothing: true, status: 404
    else
      # respond_to do |format|
      #   format.json { render @advisory }
      # end
      render @advisory
    end
  end
end
