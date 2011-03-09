class User < ActiveRecord::Base
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :name
end
