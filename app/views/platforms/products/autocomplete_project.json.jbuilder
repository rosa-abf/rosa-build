json.array!(@items) do |item|
  json.id               item.id
  json.name             item.name_with_owner
  json.project_versions grouped_options_for_select(versions_for_group_select(item))
end
