ActiveAdmin.register User do

  menu priority: 2

  filter :uname
  filter :email
  filter :role, as: :select, collection: User::EXTENDED_ROLES
  filter :created_at

  controller do
    def update(options={}, &block)
      user_params = params[:user]
      resource.role = user_params.delete(:role)
      user_params.delete(:password) if user_params[:password].blank?
      user_params.delete(:password_confirmation) if user_params[:password_confirmation].blank?
      super
    end
  end

  index do
    column :id
    column(:uname) do |user|
      link_to(user.uname, user_path(user))
    end
    column :email
    column :created_at
    column :role

    default_actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :uname
      f.input :role,      as: :select, collection: User::EXTENDED_ROLES, include_blank: false
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  action_item only: %i(show edit) do
    link_to 'Reset token', reset_token_admin_user_path(resource),
      'data-method' => :put,
      data:         { confirm: 'Are you sure you want to reset token?' }
  end

  action_item only: :show do
    link_to 'Login as user', login_as_admin_user_path(resource)
  end

  member_action :reset_token, :method => :put do
    resource.reset_authentication_token!
    flash[:info] = 'User token reseted successfully'
    redirect_to admin_user_path(resource)
  end

  member_action :login_as do
    sign_in(resource, bypass: true)
    redirect_to root_path
  end

end
