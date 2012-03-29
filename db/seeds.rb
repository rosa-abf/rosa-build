# -*- encoding : utf-8 -*-
ARCHES = %w(i386 i586 x86_64)
ARCHES.each do |arch|
  Arch.find_or_create_by_name arch
end
