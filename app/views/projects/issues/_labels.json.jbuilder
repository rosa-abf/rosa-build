json.array!(project.labels) do |label|
  json.id       label.id
  json.name     label.name
  json.color    label.color

  json.default_style do
    json.set! 'background-color', "##{label.color}"
    json.color                    '#FFF'
  end

  if defined?(all_issue_ids)
    selected = params[:labels].include?(label.name)
    json.selected selected
    json.style do
      json.set! 'background-color', "##{label.color}"
      json.color                    '#FFF'
    end if selected

    json.count Labeling.joins(:label).where(
                issue_id:     all_issue_ids,
                labels: {
                  name:       label.name,
                  project_id: project.id
                }
               ).count
  end
end
