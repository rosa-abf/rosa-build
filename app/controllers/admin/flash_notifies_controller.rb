class Admin::FlashNotifiesController < Admin::BaseController
  def index
    @flash_notifies = FlashNotify.paginate(page: params[:page], per_page: 20)
  end

  def new
    @flash_notify = FlashNotify.new(published: true)
  end

  def create
    @flash_notify = FlashNotify.new(params[:flash_notify])
    if @flash_notify.save
      flash[:notice] = t("flash.flash_notify.saved")
      redirect_to admin_flash_notifies_path
    else
      flash[:error] = t("flash.flash_notify.save_error")
      flash[:warning] = @flash_notify.errors.full_messages.join('. ')
      render :new
    end
  end

  def update
    if @flash_notify.update_attributes(params[:flash_notify])
      flash[:notice] = t("flash.flash_notify.saved")
      redirect_to admin_flash_notifies_path
    else
      flash[:error] = t("flash.flash_notify.save_error")
      flash[:warning] = @flash_notify.errors.full_messages.join('. ')
      render :edit
    end
  end

  def destroy
    if @flash_notify.destroy
      flash[:notice] = t("flash.flash_notify.destroyed")
    else
      flash[:error] = t("flash.flash_notify.destroy_error")
    end
    redirect_to admin_flash_notifies_path
  end
end
