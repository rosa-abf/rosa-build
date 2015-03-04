class Platforms::KeyPairsController < Platforms::BaseController
  before_action :authenticate_user!

  load_and_authorize_resource :platform
  load_and_authorize_resource only: [:create, :destroy]

  def index
    @key_pair = KeyPair.new
  end

  def create
    @key_pair.user_id = current_user.id

    if @key_pair.save
      flash[:notice] = t('flash.key_pairs.saved')
      redirect_to platform_key_pairs_path(@key_pair.repository.platform) and return
    else
      flash[:error] = t('flash.key_pairs.save_error')
    end
    render :index
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
