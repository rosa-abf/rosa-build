class SubscribesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_instances
  before_filter :set_subscribeable

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
    @subscribeable.subscribes.where(:user_id => current_user.id)[0].destroy

    flash[:notice] = t("flash.subscribe.destroyed")
    redirect_to :back
  end

  private

  # Sets instances for parent resources (@issue, etc.)
  def set_instances
    params.each do |name, value|
      if name =~ /(.+)_id$/
        instance_variable_set "@"+$1, $1.classify.constantize.find(value)
      end
    end
  end

  # Sets current parent resource by setted instance
  def set_subscribeable
    @subscribeable = @issue if @issue
  end
end
