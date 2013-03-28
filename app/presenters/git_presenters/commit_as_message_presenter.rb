# -*- encoding : utf-8 -*-
class GitPresenters::CommitAsMessagePresenter < ApplicationPresenter
  include CommitHelper

  attr_accessor :commit
  attr_reader :header, :image, :date, :caption, :content, :expandable, :is_reference_to_issue, :committer

  def initialize(commit, opts = {})
    comment = opts[:comment]
    @is_reference_to_issue = !!comment # is it reference issue from commit
    @project = if comment
                        Project.where(:id => opts[:comment].data[:from_project_id]).first
                      else
                        opts[:project]
                      end
    if @project
      commit = commit || @project.repo.commit(comment.data[:commit_hash])

      @committer = User.where(:email => commit.committer.email).first || commit.committer
      @commit_hash = commit.id
      @committed_date, @authored_date = commit.committed_date, commit.authored_date
      @commit_message = commit.message
    else
      @committer = t('layout.commits.unknown_committer')
      @commit_hash = comment.data[:commit_hash]
      @committed_date = @authored_date = comment.created_at
      @commit_message = t('layout.commits.deleted')
    end
    prepare_message
  end

  def header
    @header ||= if @is_reference_to_issue
      I18n.t('layout.commits.reference', :committer => committer_link, :commit => commit_link)
    elsif @project.present?
      I18n.t('layout.messages.commits.header',
       :committer => committer_link, :commit => commit_link, :project => @project.name)
    end.html_safe
  end

  def image
    @image ||= if committer.is_a? User
      helpers.avatar_url(committer, :medium)
    elsif committer.is_a? Grit::Actor
      helpers.avatar_url_by_email(committer.email, :medium)
    else
      size = User.new.avatar.styles[:medium].geometry.split('x').first
      helpers.gravatar_url('email', size)
    end
  end

  def date
    @date ||= I18n.l(@committed_date || @authored_date, :format => :long)
  end

  def expandable?
    true
  end

  def buttons?
    false
  end

  def content?
    !content.blank?
  end

  def caption?
    true
  end

  def comment_id?
    false
  end

  def issue_referenced_state?
    false
  end

  protected

  def committer_link
    @committer_link ||= if committer.is_a? User
      link_to committer.uname, user_path(committer)
    elsif committer.is_a? Grit::Actor
      mail_to committer.email, committer.name
    else # unknown committer
      committer
    end
  end

  def commit_link
    if @project
      link_to shortest_hash_id(@commit_hash), commit_path(@project, @commit_hash)
    else
      shortest_hash_id(@commit_hash)
    end
  end

  def prepare_message
    (@caption, @content) = @commit_message.split("\n\n", 2)
    @caption = 'empty message' unless @caption.present?
    if @caption.length > 72
      tmp = '...' + @caption[69..-1]
      @content = (@content.present?) ? tmp + @content : tmp
      @caption = @caption[0..68] + '...'
    end
#      @content = @content.gsub("\n", "<br />").html_safe if @content
    @content = simple_format(@content, {}, :sanitize => true).html_safe if @content
  end
end
