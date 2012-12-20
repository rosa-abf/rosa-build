# -*- encoding : utf-8 -*-
class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  belongs_to :project
  serialize :data

  validates :body, :user_id, :commentable_id, :commentable_type, :project_id, :presence => true

  scope :for_commit, lambda {|c| where(:commentable_id => c.id.hex, :commentable_type => c.class)}
  default_scope order('created_at')

  after_create :subscribe_on_reply, :unless => lambda {|c| c.commit_comment?}
  after_create :subscribe_users

  attr_accessible :body, :data

  def commentable
    # raise commentable_id.inspect
    # raise commentable_id.to_s(16).inspect
    commit_comment? ? project.repo.commit(commentable_id.to_s(16)) : super # TODO leading zero problem
  end

  def commentable=(c)
    if self.class.commit_comment?(c.class)
      self.commentable_id = c.id.hex
      self.commentable_type = c.class.name
    else
      super
    end
  end

  def self.commit_comment?(class_name)
    class_name.to_s == 'Grit::Commit'
  end

  def commit_comment?
    self.class.commit_comment?(commentable_type)
  end

  def self.issue_comment?(class_name)
    class_name.to_s == 'Issue'
  end

  def issue_comment?
    self.class.issue_comment?(commentable_type)
  end

  def own_comment?(user)
    user_id == user.id
  end

  def can_notify_on_new_comment?(subscribe)
    User.find(subscribe.user).notifier.new_comment && User.find(subscribe.user).notifier.can_notify
  end

  def actual_inline_comment?(diff = nil, force = false)
    unless force
      raise "This is not inline comment!" if data.blank? # for debug
      return data[:actual] unless data[:actual].nil?
      return false if diff.nil?
    end
    return data[:actual] = true if commentable_type == 'Grit::Commit'
    filepath, line_number = data[:path], data[:line]
    diff_path = (diff || commentable.diffs ).select {|d| d.a_path == data[:path]}
    comment_line = data[:line].to_i
    # NB! also dont create a comment to the diff header
    return data[:actual] = false if diff_path.blank? || comment_line == 0
    res, ind = true, 0
    diff_path[0].diff.each_line do |line|
      if self.persisted? && (comment_line-2..comment_line+2).include?(ind) && data.try('[]', "line#{ind-comment_line}") != line.chomp
        break res = false
      end
      ind = ind + 1
    end
    if ind < comment_line
      return data[:actual] = false
    else
      return data[:actual] = res
    end
  end

  def inline_diff
    data[:strings] + data['line0']
  end

  def pull_comment?
    return true if commentable.is_a?(Issue) && commentable.pull_request.present?
  end

  def set_additional_data params
    return true if params[:path].blank? && params[:line].blank? # not inline comment
    if params[:in_reply].present? && reply = Comment.where(:id => params[:in_reply]).first
      self.data = reply.data
      return true
    end
    self.data = {:path => params[:path], :line => params[:line]}
    return actual_inline_comment?(nil, true) if commentable.is_a?(Grit::Commit)
    if commentable.is_a?(Issue) && pull = commentable.pull_request
      diff_path = pull.diff.select {|d| d.a_path == params[:path]}
      return false unless actual_inline_comment?(pull.diff, true)

      comment_line, line_number, strings = params[:line].to_i, -1, []
      diff_path[0].diff.each_line do |line|
        line_number = line_number.succ
        # Save 2 lines above and bottom of the diff comment line
        break if line_number > comment_line + 2
        if (comment_line-2..comment_line+2).include? line_number
          data["line#{line_number-comment_line}"] = line.chomp
        end

        # Save lines from the closest header for rendering in the discussion
        if line_number < comment_line
          # Header is the line like "@@ -47,9 +50,8 @@ def initialize(user)"
          if line =~ Diff::Display::Unified::Generator::LINE_NUM_RE
            strings = [line]
          else
            strings << line
          end
        end
      end
      ## Bug with numbers of diff lines, now store all diff
      data[:strings] = strings.join
      # Limit stored diff to 10 lines (see inline_diff)
      #data[:strings] = ((strings.count) <= 9 ? strings : [strings[0]] + strings.last(8)).join
      ##
      data[:view_path] = h(diff_path[0].renamed_file ? "#{diff_path[0].a_path.rtruncate 60} -> #{diff_path[0].b_path.rtruncate 60}" : diff_path[0].a_path.rtruncate(120))
    end
    return true
  end

  protected

  def subscribe_on_reply
    commentable.subscribes.create(:user_id => user_id) if !commentable.subscribes.exists?(:user_id => user_id)
  end

  def subscribe_users
    if issue_comment?
      commentable.subscribes.create(:user => user) if !commentable.subscribes.exists?(:user_id => user.id)
    elsif commit_comment?
      recipients = project.admins
      recipients << user << User.where(:email => commentable.try(:committer).try(:email)).first # commentor and committer
      recipients.compact.uniq.each do |user|
        options = {:project_id => project.id, :subscribeable_id => commentable_id, :subscribeable_type => commentable.class.name, :user_id => user.id}
        Subscribe.subscribe_to_commit(options) if Subscribe.subscribed_to_commit?(project, user, commentable)
      end
    end
  end
end
