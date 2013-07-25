json.refs_list @refs do |grit|
  json.ref grit.name
  json.object do
    json.type (grit.class.name =~ /Tag/ ? 'tag' : 'commit')
    json.sha grit.commit.id
    json.authored_date grit.commit.authored_date.to_i
  end
end