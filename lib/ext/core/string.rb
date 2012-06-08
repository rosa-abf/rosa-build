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

  # same as reverse.truncate.reverse
  def rtruncate(length, options = {})
    text = self.dup
    options[:omission] ||= "..."
    options[:separator] ||= '/'

    length_with_room_for_omission = length - options[:omission].mb_chars.length
    chars = text.mb_chars
    stop = options[:separator] ?
      (chars.index(options[:separator].mb_chars, length_with_room_for_omission) || length_with_room_for_omission) : length_with_room_for_omission

    (chars.length > length ? "#{options[:omission]}#{chars[-(stop+1)...-1]}" : text).to_s
  end
end
