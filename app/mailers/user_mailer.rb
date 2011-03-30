class UserMailer < ActionMailer::Base
  default :from => APP_CONFIG['no-reply-email'], :content_type => "text/plain"

  def new_user_notification(user)
    @user = user
    mail(:to => user.email, :subject => "Регистрация на проекте «#{APP_CONFIG['project_name']}»") do |format|
      format.text
    end
  end
end
