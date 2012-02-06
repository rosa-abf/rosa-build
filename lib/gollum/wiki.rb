# -*- encoding : utf-8 -*-
module Gollum
  class Wiki

    alias_method :native_gollum_page, :page
    alias_method :native_gollum_file, :file
    alias_method :native_gollum_write_page,  :write_page
    alias_method :native_gollum_update_page, :update_page

    def page(name, version = @ref)
      native_gollum_page(force_grit_encoding(name), version)
    end

    def file(name, version = @ref)
      native_gollum_file(force_grit_encoding(name), version)
    end

    def write_page(name, format, data, commit = {})
      native_gollum_write_page(force_grit_encoding(name), format, data, commit)
    end

    def update_page(page, name, format, data, commit = {})
      native_gollum_update_page(page, force_grit_encoding(name), format, data, commit)
    end

    private

    def force_grit_encoding(str)
      str.dup.force_encoding(Encoding::ASCII_8BIT)
    end

  end
end
