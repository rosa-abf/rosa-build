json.refs_list @refs do |grit|
  json.ref grit.name
  json.object do
    json.type (grit.class.name =~ /Tag/ ? 'tag' : 'commit')
    json.sha grit.commit.id
  end
end
json.url refs_list_api_v1_project_path(@project.id, format: :json)