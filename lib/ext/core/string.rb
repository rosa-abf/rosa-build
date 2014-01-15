require 'charlock_holmes/string'

class String
  # same as reverse.truncate.reverse
  def rtruncate(length, options = {})
    chars = self.dup.mb_chars
    return self if chars.length <= length
    options[:omission] ||= "..."
    options[:separator] ||= '/'

    start = chars.length - length + options[:omission].mb_chars.length
    stop = options[:separator] ? (chars.index(options[:separator].mb_chars, start) || start) : start
    "#{options[:omission]}#{chars[stop..-1]}".to_s
  end
end
