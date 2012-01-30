# -*- encoding : utf-8 -*-
Factory.define(:user) do |u|
  u.email { Factory.next(:email) }
  u.name { Factory.next(:string) }
  u.uname { Factory.next(:uname) }
  u.password '123456'
  u.password_confirmation { |user| user.password }
end

Factory.define(:admin, :class => 'User') do |u|
  u.email { Factory.next(:email) }
  u.name { Factory.next(:string) }
  u.uname { Factory.next(:uname) }
  u.password '123456'
  u.password_confirmation { |user| user.password }
  u.role 'admin'
end
