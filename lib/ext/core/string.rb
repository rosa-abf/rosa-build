require 'charlock_holmes/string'

class String
  def default_encoding!
    default_encoding = Encoding.default_internal || Encoding::UTF_8
    if ascii_only? # no need to encode if ascii
      force_encoding(default_encoding)
    else # should encode
      options = {invalid: :replace, undef: :replace, replace: ''}
      if (detected = detect_encoding) && detected[:encoding]
        force_encoding(detected[:encoding]).encode!(default_encoding, detected[:encoding], options)
      end
      scrub('')
      raise unless valid_encoding? # check result
    end
    self
  rescue
    replace "--broken encoding: #{detect_encoding[:encoding] || 'unknown'}"
  # ensure
  #   return self
  end

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
