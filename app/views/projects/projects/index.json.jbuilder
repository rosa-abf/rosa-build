json.sEcho h(params[:sEcho].to_i || -1)
json.iTotalRecords @projects[:total_count]
json.iTotalDisplayRecords @projects[:filtered_count]

json.messages do |msg|
  msg.remove_confirm t("layout.confirm")
end

json.icons do |icons|
  icons.visibilities do |vis|
    Project::VISIBILITIES.each do |visibility|
      vis.set!(visibility, image_path(visibility_icon(visibility)))
    end
  end
end

json.aaData do |aadata|
  aadata.array!(@projects[:projects]) do |json, proj|
    json.partial! 'project', project: proj
  end
end
