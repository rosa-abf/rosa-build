# -*- encoding : utf-8 -*-
class Avatar < ActiveRecord::Base
  self.abstract_class = true

  MAX_AVATAR_SIZE = 5.megabyte

  has_attached_file :avatar, :styles =>
    { :micro => { :geometry => "16x16#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'},
       :small => { :geometry => "30x30#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'},
       :medium => { :geometry => "40x40#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'},
       :big => { :geometry => "81x81#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'}
    }
  validates_inclusion_of :avatar_file_size, :in => (0..MAX_AVATAR_SIZE), :allow_nil => true

  attr_accessible :avatar

end
