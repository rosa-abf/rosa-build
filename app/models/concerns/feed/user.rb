module Feed::User
  extend ActiveSupport::Concern

  included do
    after_commit :new_user_notification, on: :create
  end

  private

  def new_user_notification
    ActivityFeed.create(
      user: self,
      kind: 'new_user_notification',
      data: {user_name: self.user_appeal, user_email: self.email}
    )
  end

end