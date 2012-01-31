# -*- encoding : utf-8 -*-
module Gollum
  class Page
    alias_method :native_gollum_name, :name

    def name
      native_gollum_name.force_encoding(Encoding.default_internal || Encoding::UTF_8)
    end

  end
end
