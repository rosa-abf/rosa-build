# -*- encoding : utf-8 -*-
module PaginateHelper

  def paginate_params
    per_page = params[:per_page].to_i
    per_page = 20 if per_page < 1
    per_page = 100 if per_page >100
    page = params[:page].to_i
    page = nil if page == 0
    {:page => page, :per_page => per_page}
  end

end
