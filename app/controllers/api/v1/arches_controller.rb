class Api::V1::ArchesController < Api::V1::BaseController
  # before_action :authenticate_user! unless APP_CONFIG['anonymous_access']

  def index
    authorize :arch
    @arches = Arch.order(:id).paginate(paginate_params)
  end

end
