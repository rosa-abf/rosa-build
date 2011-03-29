require 'digest/md5'
class User < ActiveRecord::Base
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :name

  before_validation :generate_password, :on => :create
  after_create :send_notification_email

  protected

    def generate_password
      if self.password.blank?
        self.password = self.password_confirmation = Digest::MD5.hexdigest(Date.today.to_s)[0..6] 
      end
    end

    def send_notification_email
      UserMailer.new_user_notification(self).deliver
    end
end
