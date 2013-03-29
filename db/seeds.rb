# -*- encoding : utf-8 -*-
ARCHES = %w(i386 i586 x86_64)
ARCHES.each do |arch|
  Arch.find_or_create_by_name arch
end

%w(rosa_system iso_worker_1 file_store).each do |uname|
  user = User.new uname: uname, email: "#{uname}@rosalinux.ru", password: SecureRandom.base64
  user.confirmed_at, user.role = Time.now.utc, 'system'; user.save
end

admin = User.new uname: 'admin', email: 'admin@rosalinux.ru', password: 'qwerty'
admin.confirmed_at, admin.role = Time.now.utc, 'admin'; admin.save