class Settings::NotifiersController < ApplicationController
  layout "sessions"

  before_filter :authenticate_user!

  load_and_authorize_resource :user
  load_and_authorize_resource :class => Settings::Notifier, :through => :user, :singleton => true, :shallow => true

  def show
  end

  def update
    if @notifier.update_attributes(params[:settings_notifier])
      flash[:notice] = I18n.t("flash.settings.saved")
      redirect_to [@user, @notifier]
    else
      flash[:notice] = I18n.t("flash.settings.save_error")
      redirect_to [@user, @notifier]
    end
  end

end