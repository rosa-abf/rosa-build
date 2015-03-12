# Private: Finders of all sorts: methods to find FlashNotify records, methods to find
# other records which belong to given FlashNotify.
#
# This module gets included into FlashNotify.
module FlashNotify::Finders
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(published: true) }

    after_commit :clear_caches
    after_touch  :clear_caches
  end

  module ClassMethods

    # Public: Get cached first published FlashNotify record.
    #
    # Returns FlashNotify record or nil.
    def published_first_cached
      Rails.cache.fetch('FlashNotify.published.first') do
        published.first
      end
    end
  end

  protected

  # Private: after_commit and after_touch hook which clears find_cached cache.
  def clear_caches
    Rails.cache.delete('FlashNotify.published.first')
  end
end
