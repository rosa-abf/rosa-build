module EmptyMetadata
  extend ActiveSupport::Concern

  included do
    after_create :create_empty_metadata
  end

  def create_empty_metadata
    return if is_a?(Platform) && personal?
    Resque.enqueue(CreateEmptyMetadataJob, self.class.name, id)
  end

end
