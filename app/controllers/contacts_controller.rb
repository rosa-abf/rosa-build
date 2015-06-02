class ContactsController < ApplicationController
  skip_after_action :verify_authorized

  def new
    @form = Feedback.new(current_user)
  end

  def create
    @form = Feedback.new(feedback_params)
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

  private

  def feedback_params
    params[:feedback].permit(:name, :email, :subject, :message)
  end

end
