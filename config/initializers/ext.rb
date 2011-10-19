# Load extensions to existing classes.
Dir["lib/ext/**/*.rb"].each do |fn|
  require File.expand_path( fn )
end
