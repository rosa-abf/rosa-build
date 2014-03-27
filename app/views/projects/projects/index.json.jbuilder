json.sEcho h(params[:sEcho].to_i || -1)
json.iTotalRecords @projects[:total_count]
json.iTotalDisplayRecords @projects[:filtered_count]

json.messages do
  json.remove_confirm t("layout.confirm")
end

json.icons do
  json.visibilities do
    Project::VISIBILITIES.each do |visibility|
      json.set!(visibility, image_path(visibility_icon(visibility)))
    end
  end
end

json.aaData do
  json.array!(@projects[:projects]) do |proj|
    json.partial! 'project', project: proj
  end
end
