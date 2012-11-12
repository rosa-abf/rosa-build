class IntegrateNewIsoBuilderWithProducts < ActiveRecord::Migration
  def up
    remove_column :products, :build_script
    remove_column :products, :counter
    remove_column :products, :ks
    remove_column :products, :menu
    remove_column :products, :tar_file_name
    remove_column :products, :tar_content_type
    remove_column :products, :tar_file_size
    remove_column :products, :tar_updated_at
    remove_column :products, :cron_tab
    remove_column :products, :use_cron

    add_column :products, :project_id, :integer
    add_column :product_build_lists, :project_id, :integer

    add_column :product_build_lists, :project_version, :string
    add_column :product_build_lists, :commit_hash, :string

    add_column :product_build_lists, :params, :string
    add_column :products, :params, :string

    add_column :product_build_lists, :main_script, :string
    add_column :products, :main_script, :string

    add_column :product_build_lists, :results, :text

    add_column :products, :time_living, :integer
    add_column :product_build_lists, :time_living, :integer
  end

  def down
    add_column :products, :build_script, :text
    add_column :products, :counter, :text
    add_column :products, :ks, :text
    add_column :products, :menu, :text
    add_column :products, :tar_file_name, :string
    add_column :products, :tar_content_type, :string
    add_column :products, :tar_file_size, :integer
    add_column :products, :tar_updated_at, :timestamp
    add_column :products, :cron_tab, :text
    add_column :products, :use_cron, :boolean

    remove_column :products, :project_id
    remove_column :product_build_lists, :project_id

    remove_column :product_build_lists, :project_version
    remove_column :product_build_lists, :commit_hash

    remove_column :product_build_lists, :params
    remove_column :products, :params
    
    remove_column :product_build_lists, :main_script
    remove_column :products, :main_script

    remove_column :product_build_lists, :results
    
    remove_column :product_build_lists, :time_living
    remove_column :products, :time_living
  end
end
