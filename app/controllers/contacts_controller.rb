class ContactsController < ApplicationController

  def new
    @form = Feedback.new(current_user)
  end

  def create
    @form = Feedback.new(params[:feedback])
    if @form.perform_send
      flash[:notice] = I18n.t("flash.contact.success")
      redirect_to sended_contact_path
    else
      flash[:error] = I18n.t("flash.contact.error")
      render :new and return
    end
  end

  def sended
  end

end
