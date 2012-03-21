# -*- encoding : utf-8 -*-
require 'charlock_holmes/string'
# require 'iconv'

class String
  def default_encoding!
    if ascii_only?
      force_encoding(Encoding.default_internal || Encoding::UTF_8)
    else
      force_encoding((detected = detect_encoding and detected[:encoding]) || Encoding.default_internal || Encoding::UTF_8).encode!
    end
  end

  # def enforce_utf8(from = nil)
  #   begin
  #     is_utf8? ? self : ::Iconv.iconv('utf8', from, self).first
  #   rescue
  #     converter = ::Iconv.new('UTF-8//IGNORE//TRANSLIT', 'ASCII//IGNORE//TRANSLIT')
  #     # If Ruby 1.9, else another RubyEngine (ree, Ruby 1.8)
  #     begin 
  #       converter.iconv(self).unpack('U*').select{|cp| cp < 127}.pack('U*').force_encoding('utf-8')
  #     rescue
  #       converter.iconv(self).unpack('U*').select{|cp| cp < 127}.pack('U*')
  #     end
  #   end
  # end  
end
