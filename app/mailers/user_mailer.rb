# -*- encoding : utf-8 -*-

class UserMailer < ActionMailer::Base
  default :from => APP_CONFIG['do-not-reply-email']

  include Resque::Mailer # send email async

  def new_user_notification(user)
    @user = user
    mail(:to => user.email, :subject => I18n.t("notifications.subjects.new_user_notification", :project_name => APP_CONFIG['project_name'])) do |format|
      format.html
    end
  end

  def new_comment_notification(comment, user)
    @user = user
    @comment = comment
    mail(:to => user.email, :subject => I18n.t("notifications.subjects.new_#{comment.commit_comment? ? 'commit_' : ''}comment_notification")) do |format|
      format.html
    end
  end

  def new_issue_notification(issue, user)
    @user = user
    @issue = issue
    mail(:to => user.email, :subject => I18n.t("notifications.subjects.new_issue_notification")) do |format|
      format.html
    end
  end

  def issue_assign_notification(issue, user)
    @user = user
    @issue = issue
    mail(:to => user.email, :subject => I18n.t("notifications.subjects.issue_assign_notification")) do |format|
      format.html
    end
  end

  def build_list_notification(build_list, user)
    I18n.locale = user.language if user.language
    @user = user
    @build_list = build_list

    subject = "[#{build_list.bs_id.present? ? build_list.bs_id : t("layout.build_lists.bs_id_not_set")}] "
    subject << "«#{build_list.project ? build_list.project.name_with_owner : t("layout.projects.unexisted_project")}», "
    subject << user.name
    subject << " - #{build_list.human_status}"
    mail(:to => user.email, :subject =>subject) do |format|
      format.html
    end
  end

  def invite_approve_notification(register_request)
    I18n.locale = register_request.language if register_request.language
    @register_request = register_request
    mail :to => register_request.email, :subject => I18n.t("notifications.subjects.invite_approve_notification") do |format|
      format.html
    end
  end
end
