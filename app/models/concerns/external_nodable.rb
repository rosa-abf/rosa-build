module ExternalNodable
  extend ActiveSupport::Concern

  EXTERNAL_NODES = %w(owned everything)

  included do
    validates :external_nodes,
              inclusion:              { in: EXTERNAL_NODES },
              allow_blank:            true
  end

end
