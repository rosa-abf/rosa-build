ActiveAdmin.register NodeInstruction do
  permit_params :instruction, :user_id, :output, :status

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

    actions
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
      row(:output) do |ni|
        ni.output.to_s.lines.join('<br/>').html_safe
      end
    end
  end

  sidebar 'Actions', only: :show do

    %w(disable ready restart restart_failed).each do |state|
      div do
        link_to state.humanize, force_admin_node_instruction_path(resource, state: state), method: :patch
      end if resource.send("can_#{state}?")
    end

  end

  sidebar 'Actions', only: :index do
    locked = NodeInstruction.all_locked?
    span(class: "status_tag #{locked ? 'red' : 'green'}") do
      if locked
        link_to 'Unlock instructions', unlock_all_admin_node_instructions_path, method: :post
      else
        link_to 'Lock instructions', lock_all_admin_node_instructions_path, method: :post
      end
    end
  end

  collection_action :lock_all, method: :post do
    NodeInstruction.lock_all
    flash[:notice] = 'Locked successfully'
    redirect_to admin_node_instructions_path
  end

  collection_action :unlock_all, method: :post do
    NodeInstruction.unlock_all
    flash[:notice] = 'Unlocked successfully'
    redirect_to admin_node_instructions_path
  end

  member_action :force, method: :patch do
    resource.send(params[:state])
    flash[:notice] = 'Updated successfully'
    redirect_to admin_node_instruction_path(resource)
  end

end
