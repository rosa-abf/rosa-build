module Feed::User
  extend ActiveSupport::Concern

  included do
    after_commit :new_user_notification, on: :create
  end

  private

  def new_user_notification
    activity_feeds.create(
      kind: 'new_user_notification',
      data: { user_name: user_appeal, user_email: email }
    )
  end

end