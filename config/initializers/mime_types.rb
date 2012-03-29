# -*- encoding : utf-8 -*-
# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register "text/plain", 'diff'
Mime::Type.register "text/plain", 'patch'

# add rpm spec as mime type for *.spec files
[["text/x-python",   ['py'],     '8bit'],
 ["text/x-rpm-spec", ['spec'],   '8bit'],
 ["text/x-csrc",     ['h', 'c'], '8bit'],
 ["text/x-c++src",   ['cpp'],    '8bit']
].each do |type|
  MIME::Types.add MIME::Type.from_array(type)
end
