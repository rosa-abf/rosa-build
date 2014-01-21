json.user do
  json.(@user, :id, :name, :email, :uname,:language, :own_projects_count, :professional_experience, :site, :company, :location, :build_priority)
  json.created_at @user.created_at.to_i
  json.updated_at @user.updated_at.to_i
  json.avatar_url avatar_url(@user,:big)
  json.url api_v1_user_path(@user.id, format: :json)
  json.html_url user_path(@user.uname)
  json.(@user, :role) if action_name == 'show_current_user'
end