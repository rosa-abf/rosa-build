users = @users.map do |user|
  link_block = [
    (link_to t('layout.edit'), edit_admin_user_path(user) if policy(user).edit? && !@system_list),
    (link_to t('layout.users.reset_token'), reset_auth_token_admin_user_path(user), method: :put, data: { confirm: t('layout.users.confirm_reset_token') } if policy(user).edit? && @system_list),
    (link_to t('layout.delete'), admin_user_path(user), method: :delete, data: { confirm: t('layout.users.confirm_delete') } if policy(user).destroy?
  ].compact.join('&nbsp;|&nbsp;').html_safe

  if !@system_list
    [
      user.name,
      (policy(user).read? ? link_to(user.uname, user) : user.uname),
      user.email,
      user.created_at.to_date,
      content_tag(:span, user.role, style: user.access_locked? ? 'background: #FEDEDE' : ''),
      link_block
    ]
  else
    [
      user.uname,
      link_block
    ]
  end
end


json.sEcho                params[:sEcho].to_i || -1
json.iTotalRecords        @total_users
json.iTotalDisplayRecords @users.count
json.aaData               users
