class AbbSha1ToBuildListPackage < ActiveRecord::Migration[8.1]
  def change
    add_column :build_list_packages, :sha1, :string
  end
end
