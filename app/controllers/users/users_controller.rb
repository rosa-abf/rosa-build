class Users::UsersController < Users::BaseController
  skip_before_action :authenticate_user!, only: [:allowed, :check, :discover]
  before_action :find_user_by_key, only: [:allowed, :discover]

  def allowed
    project = Project.find_by_owner_and_name! params[:project]
    action = case params[:action_type]
                  when 'git-upload-pack'
                    then :read
                  when 'git-receive-pack'
                    then :write
                  end
    render inline: (!@user.access_locked? && Ability.new(@user).can?(action, project)).to_s
  end

  def check
    render nothing: true
  end

  def discover
    render json: {name: @user.name}.to_json
  end

  protected

  def find_user_by_key
    key = SshKey.find(params[:key_id])
    @user = key.user
  end
end
