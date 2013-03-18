Dir[File.join(File.dirname(__FILE__), 'plugins', '*.rb')].each do |f|
  $:.unshift File.dirname(f)
  require f
end
