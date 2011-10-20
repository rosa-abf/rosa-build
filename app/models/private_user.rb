class PrivateUser < ActiveRecord::Base
  require 'digest/sha2'
  require 'active_support/secure_random'

  validate :login, :uniqueness => true

  class << self
  	def generate_pair(platform_id)
  	  login = "login_#{ActiveSupport::SecureRandom.hex(16)}"
      pass = "pass_#{ActiveSupport::SecureRandom.hex(16)}"

      PrivateUser.create(
        :login => login, 
        :password => Digest::SHA2.new.hexdigest(pass), 
        :platform_id => platform_id
      )

      {:login => login, :pass => pass}
  	end
  end
end