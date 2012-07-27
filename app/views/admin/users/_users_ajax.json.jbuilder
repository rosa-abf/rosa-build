users = @users.map do |user|
  link_block = [
    (link_to t('layout.show'), user if can? :read, user),
    (link_to t('layout.edit'), edit_admin_user_path(user) if can? :edit, user),
    (link_to t('layout.delete'), admin_user_path(user), :method => :delete, :confirm => t('layout.users.confirm_delete') if can? :destroy, user)
  ].compact.join('&nbsp;|&nbsp;').html_safe

  [
    user.name,
    user.uname,
    user.email,
    content_tag(:span, user.role, :style => user.access_locked? ? 'background: #FEDEDE' : ''),
    link_block
  ]
end


json.sEcho                params[:sEcho].to_i || -1
json.iTotalRecords        @total_users
json.iTotalDisplayRecords @users.count
json.aaData               users
