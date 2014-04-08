module ActivityFeedsHelper
  def render_activity_feed(activity_feed)
    render activity_feed.partial, activity_feed.data.merge(activity_feed: activity_feed)
  end

  def get_feed_title_from_content(content)
    # removes html tags and haml generator indentation whitespaces and new line chars:
    feed_title = strip_tags(content).gsub(/(^\s+|\n|  )/, ' ')
    # removes multiple whitespaces in a row and strip it:
    feed_title = feed_title.gsub(/\s{2,}/, ' ').strip
  end

  def get_user_from_activity_item(item)
    email = item.data[:user_email]
    User.where(email: email).first || User.new(email: email) if email.present?
  end

  def user_link(user, user_name, full_url = false)
    user.persisted? ? link_to(user_name, full_url ? user_url(user) : user_path(user)) : user_name
  end

  def get_title_from_activity_item(item, opts = {})
    case item.kind
      when 'new_comment_notification'
        res = t('notifications.bodies.new_comment_notification.title', { user_link: nil })
        res << ' ' << t('notifications.bodies.new_comment_notification.content',
          { issue_link: link_to(item.data[:issue_title], opts[:path]) })
      when 'git_new_push_notification'
        res = t("notifications.bodies.#{item.data[:change_type]}_branch",
          { branch_name: item.data[:branch_name], user_link: nil })
        res << ' ' << t('notifications.bodies.project', project_link: link_to(opts[:project_name_with_owner], opts[:path]))
      else nil
      end
    raw res
  end

  def get_path_from_activity_item(item, opts = {})
    case item.kind
    when 'new_comment_notification'
      project_issue_path(opts[:project_name_with_owner], item.data[:issue_serial_id])
    when 'git_new_push_notification'
      project_path(opts[:project_name_with_owner])
    else
      '?'
    end
  end
end
