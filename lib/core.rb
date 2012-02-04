Dir.glob(File.join('.', 'lib', 'ext', 'core', '*')) do |file|
  require file
end
