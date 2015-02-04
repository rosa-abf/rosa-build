json.advisories do
  json.array!(@advisories) do |item|
    json.cache! item, expires_in: 10.minutes do
      json.id item.advisory_id
      json.link advisory_path(item)
      json.description  truncate(item.description, length: 100)
      json.platforms do
        json.array!(item.platforms) do |pl|
          json.name platform_printed_name(pl)
          json.link platform_path(pl)
        end
      end
      json.projects do
        json.array!(item.projects) do |pr|
          json.name pr.name
          json.link project_path(pr)
        end
      end
    end
  end
end

json.page              params[:page]
json.advisories_count  @advisories_count
