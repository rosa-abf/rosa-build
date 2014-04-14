ActiveAdmin.register NodeInstruction do

  menu priority: 3

  controller do
    def scoped_collection
      NodeInstruction.includes(:user)
    end
  end

  filter :user_uname, as: :string
  filter :status,     as: :select, collection: NodeInstruction::STATUSES
  filter :updated_at

  index do
    column :id
    column :user

    column(:status, sortable: :status) do |ni|
      status_tag(ni.status, status_color(ni))
    end
    column :updated_at

    default_actions
  end

  form do |f|
    f.inputs do
      f.input :user,        as: :select, include_blank: false, collection: User.system.map { |u| [u.uname, u.id]  }
      f.input :status,      as: :select, include_blank: false, collection: NodeInstruction::STATUSES
      f.input :instruction, as: :text
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row(:status, sortable: :status) do |ni|
        status_tag(ni.status, status_color(ni))
      end
      row :created_at
      row :updated_at
      row :instruction
      row :output
    end
  end

  sidebar 'Actions', only: :show do

    %w(disable ready check restart fail).each do |state|
      div do
        link_to state.humanize, force_admin_node_instruction_path(resource, state: state), method: :patch
      end if resource.send("can_#{state}?")
    end

  end

  member_action :force, method: :patch do
    if NodeInstruction::STATUSES.include?(params[:state])
      resource.send(params[:state])
      flash[:info] = 'Action added to queue successfully'
    end
    redirect_to admin_node_instruction_path(resource)
  end

end
