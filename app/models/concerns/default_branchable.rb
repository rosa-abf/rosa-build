module DefaultBranchable
  extend ActiveSupport::Concern

  included do
    validates :default_branch,
              length:     { maximum: 100 }

    # attr_accessible :default_branch
  end

end
