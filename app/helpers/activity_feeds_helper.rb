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
    email = item.data[:creator_email]
    User.where(email: email).first || User.new(email: email) if email.present?
  end

  def user_link(user, user_name, full_url = false)
    user.persisted? ? link_to(user_name, full_url ? user_url(user) : user_path(user)) : user_name
  end

  def get_feed_build_list_status_message(status)
    message, error = case status
        when BuildList::BUILD_PENDING
          ['pending', nil]
        when BuildList::BUILD_PUBLISHED
          ['published', nil]
        when BuildList::SUCCESS
          ['success', nil]
        else ['failed', t("layout.build_lists.statuses.#{BuildList::HUMAN_STATUSES[status]}")]
    end
    " #{t("notifications.bodies.build_status.#{message}", error: error)}"
  end
end
