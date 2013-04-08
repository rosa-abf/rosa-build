# -*- encoding : utf-8 -*-

class UserMailer < ActionMailer::Base
  default :from => "\"#{APP_CONFIG['project_name']}\" <#{APP_CONFIG['do-not-reply-email']}>"
  default_url_options.merge!(:protocol => 'https') if APP_CONFIG['mailer_https_url']

  include Resque::Mailer # send email async

  def new_user_notification(user)
    @user = user
    mail(
      :to           => email_with_name(user, user.email),
      :subject      => I18n.t("notifications.subjects.new_user_notification",
      :project_name => APP_CONFIG['project_name'])
    ) do |format|
      format.html
    end
  end

  def new_comment_notification(comment, user)
    @user, @comment = user, comment
    subject = @comment.issue_comment? ? subject_for_issue(@comment.commentable) :
      I18n.t('notifications.subjects.new_commit_comment_notification')
    mail(
      :to       => email_with_name(user, user.email),
      :subject  => subject,
      :from     => email_with_name(comment.user)
    ) do |format|
      format.html
    end
  end

  def new_issue_notification(issue, user)
    @user, @issue = user, issue
    mail(
      :to       => email_with_name(user, user.email),
      :subject  => subject_for_issue(issue, true),
      :from     => email_with_name(issue.user)
    ) do |format|
      format.html
    end
  end

  def issue_assign_notification(issue, user)
    @user, @issue = user, issue
    mail(
      :to       => email_with_name(user, user.email),
      :subject  => subject_for_issue(@issue)
    ) do |format|
      format.html
    end
  end

  def build_list_notification(build_list, user)
    I18n.locale = user.language if user.language
    @user, @build_list = user, build_list

    subject = "[№ #{build_list.bs_id.present? ? build_list.bs_id : t("layout.build_lists.bs_id_not_set")}] "
    subject << (build_list.project ? build_list.project.name_with_owner : t("layout.projects.unexisted_project"))
    subject << " - #{build_list.human_status} "
    subject << I18n.t("notifications.subjects.for_arch", :arch => @build_list.arch.name)
    mail(
      :to       => email_with_name(user, user.email),
      :subject  => subject,
      :from     => email_with_name(build_list.publisher || build_list.user)
    ) do |format|
      format.html
    end
  end

  def invite_approve_notification(register_request)
    I18n.locale = register_request.language if register_request.language
    @register_request = register_request
    mail(
      :to       => register_request.email,
      :subject  => I18n.t("notifications.subjects.invite_approve_notification")
    ) do |format|
      format.html
    end
  end

  protected

  def email_with_name(user, email = APP_CONFIG['do-not-reply-email'])
    "\"#{user.user_appeal}\" <#{email}>"
  end

  def subject_for_issue(issue, new_issue = false)
    subject = new_issue ? '' : 'Re: '
    subject << "[#{issue.project.name}] #{issue.title} (##{issue.serial_id})"
  end
end
