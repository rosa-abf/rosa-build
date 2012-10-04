# -*- encoding : utf-8 -*-
class Api::V1::ArchesController < Api::V1::BaseController
  skip_before_filter :authenticate_user!, :only => [:index] if APP_CONFIG['anonymous_access']

  def index
    @arches = Arch.order(:id).all
  end

end