class Avatar < ActiveRecord::Base
  self.abstract_class = true

  MAX_AVATAR_SIZE = 5.megabyte
  AVATAR_SIZES = {micro: 16, small: 30, medium: 40, big: 81}

  AVATAR_SIZES_HASH = {}.tap do |styles|
    AVATAR_SIZES.each do |name, size|
      styles[name] = { geometry: "#{size}x#{size}#",  format: :jpg, convert_options: '-strip -background white -flatten -quality 70'}
    end
  end
  has_attached_file :avatar, styles: AVATAR_SIZES_HASH
  validates_inclusion_of :avatar_file_size, in: (0..MAX_AVATAR_SIZE), allow_nil: true
  validates_attachment_content_type :avatar, content_type: /\Aimage/
  validates_attachment_file_name :avatar, matches: [ /(png|jpe?g|gif|bmp|tif?f)\z/i ]

  attr_accessible :avatar

end
