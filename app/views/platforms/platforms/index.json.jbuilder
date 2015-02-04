json.platforms do
  json.array!(@platforms) do |item|
    json.cache! item, expires_in: 10.minutes do
      json.name             platform_printed_name(item)
      json.link             platform_path(item)
      json.distrib_type     item.distrib_type
      json.visibility_class fa_platform_visibility_icon(item)
    end
  end
end

json.page              params[:page]
json.platforms_count   @platforms_count
