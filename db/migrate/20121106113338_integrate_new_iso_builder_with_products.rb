class IntegrateNewIsoBuilderWithProducts < ActiveRecord::Migration
  def change
    add_column :products, :project_id, :integer
    add_column :product_build_lists, :project_id, :integer

    add_column :product_build_lists, :project_version, :string
    add_column :product_build_lists, :commit_hash, :string

    add_column :products, :lst, :string
    add_column :product_build_lists, :lst, :string

    add_column :products, :repos, :text
    add_column :product_build_lists, :repo, :string

    add_column :product_build_lists, :arch_id, :integer
  end
end
