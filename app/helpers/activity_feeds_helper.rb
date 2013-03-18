module ActivityFeedsHelper
  def render_activity_feed(activity_feed)
    render activity_feed.partial, activity_feed.data.merge(:activity_feed => activity_feed)
  end

  def get_feed_title_from_content(content)
    # removes html tags and haml generator indentation whitespaces and new line chars:
    feed_title = strip_tags(content).gsub(/(^\s+|\n|  )/, ' ')
    # removes multiple whitespaces in a row and strip it:
    feed_title = feed_title.gsub(/\s{2,}/, ' ').strip
  end

  def user_link user, user_name
    user.persisted? ? link_to(user_name, user_path(user)) : user_name
  end
end
