ActiveAdmin.register RegisterRequest do

  menu parent: 'Misc'

  index do
    column :id
    column :name

    column('User') do |request|
      user = User.find_by(email: request.email) if request.approved
      link_to(user.uname, admin_user_path(user)) if user
    end
    column :interest
    column :more
    column :created_at

    default_actions
  end

end
