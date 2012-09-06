class AddPublishWithoutQaToRepositories < ActiveRecord::Migration

  class Platform < ActiveRecord::Base
  end

  class Repository < ActiveRecord::Base
    belongs_to :platform
  end

  def up
    add_column :repositories, :publish_without_qa, :boolean, :default => true
    Repository.where('platforms.released is true').joins(:platform).
      update_all(:publish_without_qa => false)
  end

  def down
    remove_column :repositories, :publish_without_qa
  end
end
