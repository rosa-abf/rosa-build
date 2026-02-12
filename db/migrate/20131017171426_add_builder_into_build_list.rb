class AddBuilderIntoBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :builder_id, :integer #, references: nil
  end
end
