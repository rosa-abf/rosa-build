class AddExtraParamsToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :extra_params, :text
  end
end
