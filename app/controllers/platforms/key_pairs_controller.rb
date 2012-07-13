class Platforms::KeyPairsController < ApplicationController
  before_filter :authenticate_user!

  load_and_authorize_resource :platform
  load_and_authorize_resource

  skip_load_and_authorize_resource :only => [:index]
  skip_authorize_resource :platform, :only => [:create, :destroy]

  def create
    @key_pair.user_id = current_user.id

    if @key_pair.key_create_call == true
      flash[:notice] = t('flash.key_pairs.saved')
    else
      flash[:error] = t('flash.key_pairs.save_error')
      flash[:warning] = @key_pair.errors.full_messages.join('. ') unless @key_pair.errors.blank?
    end

    redirect_to platform_key_pairs_path(@platform)
  end

  def destroy
    if @key_pair.rm_key_call
      flash[:notice] = t('flash.key_pairs.destroyed')
    else
      flash[:error] = t('flash.key_pairs.destroy_error')
    end

    redirect_to platform_key_pairs_path(@platform)
  end
end
