json.refs_list @refs do |json_grit, grit|
  json_grit.ref grit.name
  json_grit.object do |json_object|
    json_object.type (grit.class.name =~ /Tag/ ? 'tag' : 'commit')
    json_object.sha grit.commit.id
    json_object.authored_date grit.commit.authored_date.strftime('%d.%m.%Y')
  end
end
json.url refs_list_api_v1_project_path(@project.id, :format => :json)