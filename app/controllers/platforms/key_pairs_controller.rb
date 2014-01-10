class Platforms::KeyPairsController < Platforms::BaseController
  before_filter :authenticate_user!

  load_and_authorize_resource :platform, :only => [:index]
  load_and_authorize_resource :only => [:create, :destroy]

  def create
    @key_pair.user_id = current_user.id

    if @key_pair.save
      flash[:notice] = t('flash.key_pairs.saved')
    else
      flash[:error] = t('flash.key_pairs.save_error')
      flash[:warning] = @key_pair.errors.full_messages.join('. ') unless @key_pair.errors.blank?
    end

    redirect_to platform_key_pairs_path(@key_pair.repository.platform)
  end

  def destroy
    if @key_pair.destroy
      flash[:notice] = t('flash.key_pairs.destroyed')
    else
      flash[:error] = t('flash.key_pairs.destroy_error')
    end

    redirect_to platform_key_pairs_path(@key_pair.repository.platform)
  end
end
