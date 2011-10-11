class User < ActiveRecord::Base
  has_many :authentications, :dependent => :destroy

  devise :database_authenticatable, :registerable, :omniauthable, # :token_authenticatable, :encryptable, :timeoutable
         :recoverable, :rememberable, :validatable #, :trackable, :confirmable, :lockable

  validates :nickname, :presence => true, :uniqueness => {:case_sensitive => false},
                       :format => {:with => /[\w]+/i} #, :exclusion => {:in => %w(superuser moderator')}

  attr_accessible :email, :password, :password_confirmation, :remember_me, :login, :nickname, :name, :ssh_key

  attr_accessor :login

  before_validation(:on => :update) { raise "Can't change nickname" if nickname_changed? } # disable edit username
  # after_create() { UserMailer.new_user_notification(self).deliver }

  class << self
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      login = conditions.delete(:login)
      where(conditions).where(["lower(nickname) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    end

    def new_with_session(params, session)
      super.tap do |user|
        if data = session["devise.omniauth_data"]
          if info = data['user_info'] and info.present?
            user.email ||= info['email'].presence
            user.nickname ||= info['nickname'].presence || info['username'].presence
            user.name ||= info['name'].presence || [info['first_name'], info['last_name']].join(' ').strip
          end
          user.password = Devise.friendly_token[0,20] # stub password
          user.authentications.build :uid => data['uid'], :provider => data['provider']
        end
      end
    end
  end

  def update_with_password(params={})
    params.delete(:current_password)
    # self.update_without_password(params) # Don't allow password update
    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end
    result = update_attributes(params)
    clean_up_passwords
    result
  end
end
