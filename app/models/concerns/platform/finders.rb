# Private: Finders of all sorts: methods to find Platform records, methods to find
# other records which belong to given Platform.
#
# This module gets included into Platform.
module Platform::Finders
  extend ActiveSupport::Concern

  included do

    scope :search_order,              -> { order(:name) }
    scope :search,                    -> (q) { where("#{table_name}.name ILIKE ?", "%#{q.to_s.strip}%") }
    scope :by_visibilities,           -> (v) { where(visibility: v) }
    scope :opened,                    -> { where(visibility: Platform::VISIBILITY_OPEN) }
    scope :hidden,                    -> { where(visibility: Platform::VISIBILITY_HIDDEN) }
    scope :by_type,                   -> (type) { where(platform_type: type) if type.present? }
    scope :main,                      -> { by_type(Platform::TYPE_MAIN) }
    scope :personal,                  -> { by_type(Platform::TYPE_PERSONAL) }
    scope :waiting_for_regeneration,  -> { where(status: Platform::WAITING_FOR_REGENERATION) }

    after_commit :clear_caches
    after_touch  :clear_caches
  end

  module ClassMethods

    # Public: Get cached Platform record by ID or slug.
    #
    # platform_id - ID or Slug (Numeric/String)
    #
    # Returns Platform record.
    # Raises ActiveRecord::RecordNotFound if nothing was found.
    def find_cached(platform_id)
      Rails.cache.fetch(['Platform.find', platform_id]) do
        find(platform_id)
      end
    end
  end

  protected

  # Private: after_commit and after_touch hook which clears find_cached cache.
  def clear_caches
    Rails.cache.delete(['Platform.find', id])
    Rails.cache.delete(['Platform.find', slug])

    if chg = previous_changes["slug"]
      Rails.cache.delete(['Platform.find', chg.first])
    end
  end
end
