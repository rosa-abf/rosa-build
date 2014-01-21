class PrivateUser < ActiveRecord::Base
  require 'digest/sha2'

  belongs_to :platform
  belongs_to :user

  validate :login, uniqueness: true

  def event_log_message
    {platform: platform.name, user: user.uname}.inspect
  end

  class << self
    def can_generate_more?(user_id, platform_id)
      !PrivateUser.exists?(user_id: user_id, platform_id: platform_id)
    end

  	def generate_pair(platform_id, user_id)
  	  login = "login_#{ActiveSupport::SecureRandom.hex(16)}"
      pass = "pass_#{ActiveSupport::SecureRandom.hex(16)}"

      PrivateUser.create(
        login: login,
        password: Digest::SHA2.new.hexdigest(pass),
        platform_id: platform_id,
        user_id: user_id
      )

      {login: login, pass: pass}
  	end
  end
end
