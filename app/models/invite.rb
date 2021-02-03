class Invite < ActiveRecord::Base
  TTL = 3.days
  MAX_UNUSED_INVITES = 5

  belongs_to :user
  belongs_to :invited_user, class_name: 'User'

  before_create :generate_invite_key

  scope :owned, ->(u) { where(user_id: u.try(:id) || u) }
  scope :unused, ->() { where(invited_user_id: nil) }
  scope :outdated, ->() { where('created_at <= ? AND invited_user_id IS NULL', TTL.ago) }

  validate :max_count_exceeded

  def used?
    !invited_user.nil?
  end

  def unused?
    invited_user.nil?
  end

  def remaining_ttl
    ret = TTL - (Time.now.utc - created_at)
    return 0 if ret < 0
    ret
  end

  private

  def generate_invite_key
    self.invite_key = SecureRandom.hex(20)
  end

  def max_count_exceeded
    if !persisted? && user_id.present? && Invite.owned(user_id).unused.count >= 5
      errors.add(
        :base,
        I18n.t('flash.invite.max_limit_exceeded', number: MAX_UNUSED_INVITES)
      )
    end
  end
end
