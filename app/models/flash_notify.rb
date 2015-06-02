require 'digest/md5'

class FlashNotify < ActiveRecord::Base
  include FlashNotify::Finders

  STATUSES = %w[error success info]

  validates :status, inclusion: {in: STATUSES}
  validates :body_ru, :body_en, :status, presence: true

  def hash_id
    @digest ||= Digest::MD5.hexdigest("#{self.id}-#{self.updated_at}")
  end

  def body(language)
    read_attribute("body_#{language}")
  end

  def should_show?(cookie_hash_id)
    cookie_hash_id != hash_id && published
  end
end
