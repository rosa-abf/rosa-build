# -*- encoding : utf-8 -*-
Dir.glob(File.join('.', 'lib', 'gollum', '*.rb')) do |file|
  require file
end
