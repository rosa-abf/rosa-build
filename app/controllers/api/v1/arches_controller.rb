class Api::V1::ArchesController < Api::V1::BaseController
  before_action :authenticate_user! unless APP_CONFIG['anonymous_access']

  def index
    @arches = Arch.order(:id).paginate(paginate_params)
    respond_to :json
  end

end
