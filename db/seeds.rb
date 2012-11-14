# -*- encoding : utf-8 -*-
ARCHES = %w(i386 i586 x86_64)
ARCHES.each do |arch|
  Arch.find_or_create_by_name arch
end

user = User.new uname: 'rosa_system', email: 'rosa_system@rosalinux.ru', password: SecureRandom.base64
user.confirmed_at = Time.now.utc; user.save

user = User.new uname: 'iso_worker_1', email: 'iso_worker_1@rosalinux.ru', password: SecureRandom.base64
user.confirmed_at = Time.now.utc; user.save