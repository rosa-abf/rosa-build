# -*- encoding : utf-8 -*-
class GitPresenters::CommitAsMessagePresenter < ApplicationPresenter
  include CommitHelper

  attr_accessor :commit, :options
  attr_reader :header, :image, :date, :caption, :content, :expandable

  def initialize(commit, opts = {})
    @commit = commit
    @options = opts#[:branch] if opts[:branch]
    prepare_message
  end

  def header
    @header ||= if options[:branch].present?
                  I18n.t("layout.messages.commits.header_with_branch",
                   :committer => committer_link, :commit => commit_link, :branch => options[:branch].name)
                elsif options[:project].present?
                  I18n.t("layout.messages.commits.header",
                   :committer => committer_link, :commit => commit_link, :project => options[:project].name)
                end.html_safe
  end

  def image
    @image ||= "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(committer.email.downcase)}?s=40&r=pg"
  end

  def date
    @date ||= I18n.l(@commit.committed_date || @commit.authored_date, :format => :long)
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

  protected

    def committer
      @committer ||= User.where(:email => @commit.committer.email).first || @commit.committer
    end

    def committer_link
      @committer_link ||= if committer.is_a? User
        link_to committer.uname, user_path(committer)
      else
        mail_to committer.email.encode_to_default, committer.name.encode_to_default
      end
    end

    def commit_link
      link_to shortest_hash_id(@commit.id), commit_path(options[:project], @commit.id)
    end

    def prepare_message
      (@caption, @content) = @commit.message.encode_to_default.split("\n\n", 2)
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
