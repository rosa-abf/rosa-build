module DefaultBranchable
  extend ActiveSupport::Concern

  included do
    validates :default_branch,
              length:     { maximum: 100 }
  end

end
