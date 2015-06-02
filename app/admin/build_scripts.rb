ActiveAdmin.register BuildScript do
  permit_params :project_name, :treeish, :commit, :sha1, :status

  menu priority: 4

  filter :project_name, as: :string

  controller do
    def scoped_collection
      BuildScript.includes(:project)
    end
  end

  index do
    column(:project) do |bs|
      link_to(bs.project.name_with_owner, project_path(bs.project))
    end
    column :treeish
    column :commit
    column :sha1

    column(:status, sortable: :status) do |bs|
      status_tag(bs.status, build_script_status_color(bs))
    end
    column :updated_at

    actions
  end

  show do
    attributes_table do
      row :id
      row(:project) do |bs|
        link_to(bs.project.name_with_owner, project_path(bs.project))
      end
      row :treeish
      row :commit
      row :sha1
      row(:status, sortable: :status) do |bs|
        status_tag(bs.status, build_script_status_color(bs))
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :project_name
      f.input :treeish
      f.input :commit
      f.input :sha1
      f.input :status,  as: :select, include_blank: false, collection: BuildScript::STATUSES
    end
    f.actions
  end

  sidebar 'Actions', only: :show do
    %w(enable disable update_archive).each do |state|
      div do
        link_to state.humanize, force_admin_build_script_path(resource, state: state), method: :patch
      end if resource.send("can_#{state}?")
    end
  end

  member_action :force, method: :patch do
    resource.send(params[:state])
    flash[:notice] = 'Updated successfully'
    redirect_to admin_build_script_path(resource)
  end

end
