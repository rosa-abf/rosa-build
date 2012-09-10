# -*- encoding : utf-8 -*-
class RegisterRequest < ActiveRecord::Base

  #---------------
  # *** Scopes ***
  #+++++++++++++++

  default_scope order('created_at ASC')

  scope :rejected, where(:rejected => true)
  scope :approved, where(:approved => true)
  scope :unprocessed, where(:approved => false, :rejected => false)

  #--------------------
  # *** Validations ***
  #++++++++++++++++++++

  validates :email, :presence => true, :uniqueness => {:case_sensitive => false}, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

  #------------------
  # *** Callbacks ***
  #++++++++++++++++++

  # before_create :generate_token
  before_update :invite_approve_notification

  #-------------------------
  # *** Instance Methods ***
  #+++++++++++++++++++++++++

  def approve
    update_attributes(:approved => true, :rejected => false)
  end # approve

  def reject
    update_attributes(:approved => false, :rejected => true)
  end # reject

  protected

  def generate_token
    self.token = Digest::SHA1.hexdigest(name + email + Time.now.to_s + rand.to_s)
  end # generate_token

  def invite_approve_notification
    puts "!!!!!!!!!!========="
    if approved_changed? && approved?
      puts "!!!!!!!!!!"
      generate_token
      UserMailer.invite_approve_notification(self).deliver
    end
  end # invite_approve_notification
end # RegisterRequest
