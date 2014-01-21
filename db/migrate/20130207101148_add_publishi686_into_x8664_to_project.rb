class AddPublishi686IntoX8664ToProject < ActiveRecord::Migration
  def change
    add_column :projects, :publish_i686_into_x86_64, :boolean, default: false
  end
end
