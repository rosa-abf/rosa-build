module ActivityFeedsHelper
  def render_activity_feed(activity_feed)
    render :partial => activity_feed.partial, :locals => activity_feed.data
  end
end
