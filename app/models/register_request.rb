class RegisterRequest < ActiveRecord::Base
  default_scope order('created_at ASC')

  scope :rejected, where(:rejected => true)
  scope :approved, where(:approved => true)
  scope :unprocessed, where(:approved => false, :rejected => false)

  before_create :generate_token

  validate :name, :presence => true
  validate :email, :presence => true, :uniqueness => {:case_sensitive => false}

  protected

    def generate_token
      token = Digest::SHA1.hexdigest(name + email + Time.now.to_s + rand.to_s)
    end
end
