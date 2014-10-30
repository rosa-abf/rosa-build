module ProductBuildListsHelper

  def product_build_list_delete_options
    [false, true].map{ |status| [t("layout.#{status}_"), status] }
  end

end
