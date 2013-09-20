class AddExtraParamsToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :extra_params, :text
  end
end
