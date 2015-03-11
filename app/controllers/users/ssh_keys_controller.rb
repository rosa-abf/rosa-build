class Users::SshKeysController < Users::BaseController
  before_action :set_current_user

  def index
    @ssh_key  = SshKey.new
  end

  def create
    @ssh_key = current_user.ssh_keys.new params[:ssh_key]

    if @ssh_key.save
      flash[:notice] = t 'flash.ssh_keys.saved'
      redirect_to ssh_keys_path
    else
      flash[:error] = t 'flash.ssh_keys.save_error'
      # flash[:warning] = @ssh_key.errors.full_messages.join('. ') unless @ssh_key.errors.blank?
      render :index
    end
  end

  def destroy
    @ssh_key = current_user.ssh_keys.find params[:id]
    if @ssh_key.destroy
      flash[:notice] = t 'flash.ssh_keys.destroyed'
    else
      flash[:error] = t 'flash.ssh_keys.destroy_error'
    end
    redirect_to ssh_keys_path
  end

end