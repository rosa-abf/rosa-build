class Users::SshKeysController < Users::BaseController
  skip_before_filter :find_user

  def index
    @ssh_keys = current_user.ssh_keys
  end

  def create
    @ssh_key = current_user.ssh_keys.new params[:ssh_key]

    if @ssh_key.save
      flash[:notice] = t 'flash.ssh_keys.saved'
    else
      flash[:error] = t 'flash.ssh_keys.save_error'
      flash[:warning] = @ssh_key.errors.full_messages.join('. ') unless @ssh_key.errors.blank?
    end
    redirect_to ssh_keys_path
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