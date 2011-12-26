class SubscribesController < ApplicationController
  def create
    @subscribe = @subscribeable.subscribes.build(:user_id => current_user.id)
    if @subscribe.save
      flash[:notice] = I18n.t("flash.subscribe.saved")
      redirect_to :back
    else
      flash[:error] = I18n.t("flash.subscribe.saved_error")
      redirect_to :back
    end
  end

  def destroy
    @subscribe = Subscribe.find(params[:id])
    @subscribe.destroy

    flash[:notice] = t("flash.subscribe.destroyed")
    redirect_to :back
  end

  private

  def find_subscribeable
    params.each do |name, value|
      if name =~ /(.+)_id$/
        return $1.classify.constantize.find(value)
      end
    end
    nil
  end
end
