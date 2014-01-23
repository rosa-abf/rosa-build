class AddPublishWithoutQaToRepositories < ActiveRecord::Migration

  class Platform < ActiveRecord::Base
    has_many :repositories, dependent: :destroy
  end

  class Repository < ActiveRecord::Base
    belongs_to :platform
  end

  def up
    add_column :repositories, :publish_without_qa, :boolean, default: true
    Platform.where(released: true).each{|p| p.repositories.update_all(publish_without_qa: false)}
    Platform.where(released: false).each{|p| p.repositories.update_all(publish_without_qa: true)}
  end

  def down
    remove_column :repositories, :publish_without_qa
  end
end
