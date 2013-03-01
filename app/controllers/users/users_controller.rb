# -*- encoding : utf-8 -*-
class Users::UsersController < Users::BaseController
  skip_before_filter :authenticate_user!, :only => :allowed

  def allowed
    key = SshKey.find(params[:key_id])
    owner_name, project_name = params[:project].split '/'
    project = Project.find_by_owner_and_name!(owner_name, project_name ? project_name : '!')
    action = case params[:action_type]
                  when 'git-upload-pack'
                    then :read
                  when 'git-receive-pack'
                    then :write
                  end
    render :inline => (!key.user.access_locked? && Ability.new(key.user).can?(action, project)) ? 'true' : 'false'
  end
end
