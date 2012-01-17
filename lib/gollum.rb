module Gollum
  class PaginateableArray < Array
    require 'will_paginate/collection'

    def paginate(options = {})
      page = options[:page] || 1
      per_page = options[:per_page] || WillPaginate.per_page
      total = options[:total_entries] || self.length

      WillPaginate::Collection.create(page, per_page, total) do |pager|
        pager.replace self[pager.offset, pager.per_page].to_a
      end
    end
  end

  class PageImproved < Page

    def versions(options = {})
      options.delete :page
      options.delete :per_page
      puts super(options)

      res = PaginateableArray.new(super(options))
      puts res.inspect
    end
  end
end
