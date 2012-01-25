class ActivityFeed < ActiveRecord::Base
  belongs_to :user

  def render_body(partial_name, locals={})
    av = ActionView::Base.new(Rails::Configuration.new.view_path)
    av.render(
      :partial => 'app/views/activity_feeds/partials/' + partial_name + '.haml',
      :locals => locals
    )
  end
end
