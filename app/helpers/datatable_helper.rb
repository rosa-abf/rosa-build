module DatatableHelper
  def page
    (params[:iDisplayStart].to_i/(params[:iDisplayLength].present? ? params[:iDisplayLength] : 25).to_i).to_i + 1
  end

  def per_page
    params[:iDisplayLength].present? ? params[:iDisplayLength] : 25
  end

  def sort_dir
    params[:sSortDir_0] == 'asc' ? 'asc' : 'desc'
  end

end
