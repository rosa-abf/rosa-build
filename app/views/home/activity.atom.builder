atom_feed do |feed|
  feed.title(t("layout.activity_feed.atom_title"))
  feed.updated(@activity_feeds[0].created_at) if @activity_feeds.length > 0

  @activity_feeds.each do |activity_feed|
    feed.entry(activity_feed, :url => root_url(:anchor => "feed#{activity_feed.id}")) do |entry|
      feed_content = raw(render(:inline => true, :partial => activity_feed.partial, :locals => activity_feed.data.merge(:activity_feed => activity_feed)))

      entry.title(truncate(get_feed_title_from_content(feed_content), :length => 50))
      entry.content(feed_content, :type => 'html')

      entry.author do |author|
        author.name(activity_feed.data[:user_name])
        author.email(activity_feed.data[:user_email])
      end if activity_feed.kind != 'git_delete_branch_notification'
    end
  end
end
