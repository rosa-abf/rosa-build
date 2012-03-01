# -*- encoding : utf-8 -*-
class CommentPresenter < ApplicationPresenter

  attr_accessor :comment, :options
  attr_reader :header, :image, :date, :caption, :content, :buttons

  def initialize(comment, opts = {})
    @comment = comment
    @user = comment.user
    @options = opts

    @content = simple_format(@comment.body, {}, :sanitize => true).html_safe
  end

  def expandable?
    false
  end

  def buttons?
    true
  end

  def content?
    true
  end

  def caption?
    false
  end
  def buttons
    project = options[:project]
    commentable = options[:commentable]
    puts "PROJECT = " + project.inspect
    puts "COMMENTABLE = " + commentable.inspect
    puts "COMMENT = " + comment.inspect
    (ep, dp) = if commentable.class == Issue
      [edit_project_issue_comment_path(project, commentable, comment),
       project_issue_comment_path(project, commentable, comment)]
    elsif commentable.class == Grit::Commit
      [edit_project_commit_comment_path(project, commentable, comment),
       project_commit_comment_path(project, commentable, comment)]
    end

    res = []
    if controller.can? :update, @comment
      res << link_to(t("layout.edit"), ep).html_safe
    end
    if controller.can? :delete, @comment
      res << link_to(t("layout.delete"), dp, :method => "delete",
                     :confirm => t("layout.comments.confirm_delete")).html_safe
    end
  end

  def header
    res = link_to @user.uname, user_path(@user.uname)
    res += ' ' + t("layout.comments.has_commented")
  end

  def image
    @image ||= "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(@user.email.downcase)}?s=40&r=pg"
  end

  def date
    @date ||= I18n.l(@comment.updated_at, :format => :long)
  end

end
