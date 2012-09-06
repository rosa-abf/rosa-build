class AddPublishWtihoutQaToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :publish_wtihout_qa, :boolean, :default => false
  end
end
