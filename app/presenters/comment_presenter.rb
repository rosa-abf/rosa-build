# -*- encoding : utf-8 -*-
class CommentPresenter < ApplicationPresenter

  attr_accessor :comment, :options
  attr_reader :header, :image, :date, :caption, :content, :buttons

  def initialize(comment, opts = {})
    @comment = comment
    @user = comment.user
    @options = opts

    @content = @comment.body
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
    project, commentable = options[:project], options[:commentable]
    path = helpers.project_commentable_comment_path(project, commentable, comment)

    res = [link_to(t("layout.link"), "#{helpers.project_commentable_path(project, commentable)}##{comment_anchor}", :class => "#{@options[:in_discussion].present? ? 'in_discussion_' : ''}link_to_comment").html_safe]
    if controller.can? :update, @comment
      res << link_to(t("layout.edit"), path, :id => "comment-#{comment.id}", :class => "edit_comment").html_safe
    end
    if controller.can? :destroy, @comment
      res << link_to(t("layout.delete"), path, :method => "delete",
                     :confirm => t("layout.comments.confirm_delete")).html_safe
    end
    res
  end

  def header
    res = link_to "#{@user.uname} (#{@user.name})", user_path(@user.uname)
    res += ' ' + t("layout.comments.has_commented")
  end

  def image
    @image ||= helpers.avatar_url(@user, :medium)
  end

  def date
    @date ||= I18n.l(@comment.updated_at, :format => :long)
  end

  def comment_id?
    true
  end

  def comment_id
    @comment.id
  end

  def comment_anchor
    # check for pull diff inline comment
    before = if @options[:add_anchor].present? && !@options[:in_discussion]
               'diff-'
             else
               ''
             end
    "#{before}comment#{@comment.id}"
  end

end
