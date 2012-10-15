json.user do |json|
  json.(@user, :id, :name, :email, :uname,:language, :own_projects_count, :professional_experience, :site, :company, :location)
  json.created_at @user.created_at.to_i
  json.updated_at @user.updated_at.to_i
  json.url api_v1_user_path(@user.id, :format => :json)
  json.html_url user_path(@user.uname)
end

json.url api_v1_user_path(@user.id, :format => :json)