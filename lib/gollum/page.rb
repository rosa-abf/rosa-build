# -*- encoding : utf-8 -*-
module Gollum
  class Page
    def name_with_encoding
      name_without_encoding.encode_to_default
    end

    alias_method_chain :name, :encoding

  end
end
