# coding: UTF-8
class UserEmailsController < ApplicationController
  layout 'sessions'
  before_filter :authenticate_user!
  respond_to :html

  #def create
  #  current_user.emails.new
  #  respond_with current_user, :location => edit_user_emails_path
  #end

  def edit
    @emails = current_user.emails
    render 'users/emails/emails'
  end

  def update
    if current_user.update_attributes params[:user]
      flash[:notice] = t('flash.user.emails.saved')
    else
      flash[:error] = t('flash.user.emails.error')
    end
    respond_with current_user, :location => edit_user_emails_path
  end

  def destroy
#    if current_user.emails.where(:id => params[:email_id]).first.destroy
#      flash[:notice] = t('flash.user.emails.delete')
#    else
      flash[:error] = t('flash.user.save_error')
#    end
    respond_with current_user, :location => edit_user_emails_path
  end
end
