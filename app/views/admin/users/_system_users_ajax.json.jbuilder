users = @users.map do |user|
  link_block = [
    (link_to t('layout.users.reset_token'), reset_auth_token_admin_user_path(user), :method => :put, :confirm => t('layout.users.confirm_reset_token') if can? :edit, user),
    (link_to t('layout.delete'), admin_user_path(user), :method => :delete, :confirm => t('layout.users.confirm_delete') if can? :destroy, user)
  ].compact.join('&nbsp;|&nbsp;').html_safe

  [
    user.uname,
    link_block
  ]
end


json.sEcho                params[:sEcho].to_i || -1
json.iTotalRecords        @total_users
json.iTotalDisplayRecords @users.count
json.aaData               users
