class CommentPresenter < ApplicationPresenter
  include PullRequestHelper

  attr_accessor :comment, :options
  attr_reader :header, :image, :date, :caption, :content, :buttons, :is_reference_to_issue,
              :reference_project

  def initialize(comment, opts = {})
    @is_reference_to_issue = !!(comment.automatic && comment.created_from_issue_id) # is it reference issue from another issue
    @comment, @user, @options = comment, comment.user, opts

    unless @is_reference_to_issue
      @content = @comment.body
    else
      issue = Issue.where(id: comment.created_from_issue_id).first
      if issue && (comment.data[:comment_id].nil? || Comment.exists?(comment.data[:comment_id]))
        @referenced_issue = issue.pull_request || issue
        @reference_project = issue.project
        title = if issue == opts[:commentable]
                     "#{issue.serial_id}"
                    elsif issue.project.owner == opts[:commentable].project.owner
                      "#{issue.project.name}##{issue.serial_id}"
                    else
                      "#{issue.project.name_with_owner}##{issue.serial_id}"
                    end
        title = "<span style=\"color: #777;\">#{title}</span>:"
        issue_link = project_issue_path(issue.project, issue)
        @content = "<a href=\"#{issue_link}\">#{title} #{issue.title}</a>".html_safe
      else
        @content = t 'layout.comments.removed'
      end
    end
  end

  def expandable?
    false
  end

  def buttons?
    !@is_reference_to_issue # dont show for automatic comment
  end

  def content?
    true
  end

  def caption?
    false
  end

  def issue_referenced_state?
    @referenced_issue # show state of the existing referenced issue
  end

  def buttons
    project, commentable = options[:project], options[:commentable]

    link_to_comment = "#{helpers.project_commentable_path(project, commentable)}##{comment_anchor}"
    klass = "#{@options[:in_discussion].present? ? 'in_discussion_' : ''}link_to_comment"
    res = [ link_to(content_tag(:i, nil, class: 'fa fa-link'),
                    link_to_comment,
                    class: klass).html_safe ]
    if controller.can? :update, @comment
      res << link_to(content_tag(:i, nil, class: 'fa fa-edit'),
                     "#update-comment#{comment.id}",
                     'ng-click' => "commentsCtrl.toggleEditForm(#{comment_id})" ).html_safe
    end
    if controller.can? :destroy, @comment
      res << link_to(content_tag(:i, nil, class: 'fa fa-close'),
                     '',
                     'ng-click' => "commentsCtrl.remove(#{comment_id})").html_safe
    end
    res
  end

  def header
    user_link = link_to @user.fullname, user_path(@user.uname)
    res = unless @is_reference_to_issue
                "#{user_link} #{t 'layout.comments.has_commented'}"
              else
                t 'layout.comments.reference', user: user_link
              end
    res.html_safe
  end

  def image
    @image ||= helpers.avatar_url(@user, :medium)
  end

  def date
    @date ||= @comment.created_at
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

  def issue_referenced_state
    if @referenced_issue.is_a? Issue
      statuses = {'open' => 'success', 'closed' => 'important'}
      content_tag :span, t("layout.issues.status.#{@referenced_issue.status}"), class: "pull-right label label-#{statuses[@referenced_issue.status]}"
    else
      pull_status_label @referenced_issue.status, class: 'pull-right'
    end.html_safe
  end
end
