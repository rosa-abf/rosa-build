# -*- encoding : utf-8 -*-
class Token < ActiveRecord::Base
  belongs_to :subject, :polymorphic => true, :touch => true
  belongs_to :creator, :class_name => 'User'
  belongs_to :updater, :class_name => 'User'

  validates :creator_id, :subject_id, :subject_type, :presence => true

  default_scope order("#{table_name}.created_at")

  before_create :generate_token

  attr_accessible :description

  state_machine :status, :initial => :active do
    event :block do
      transition [:active, :blocked] => :blocked
    end
  end

  protected

  def generate_token
    self.authentication_token = loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless Token.where(:authentication_token => token).exists?
    end
  end

end
