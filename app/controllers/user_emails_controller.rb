# coding: UTF-8
class UserEmailsController < ApplicationController
  layout 'sessions'
  before_filter :authenticate_user!

  def edit
    (5 - current_user.emails.count).times {current_user.emails.build }
    render 'users/emails/emails'
  end

  def update
    new_emails = []
    params[:user][:emails_attributes].each_value {|x| new_emails << x[:email] if x[:email].present?}
    emails = current_user.emails
    emails.each {|e| e.destroy unless new_emails.include?(e.email)}
    new_emails.each {|e| emails.create(:email => e) unless emails.include? e}

    flash[:notice] = t('flash.user.emails.saved')
    redirect_to edit_user_emails_path
  end
end
