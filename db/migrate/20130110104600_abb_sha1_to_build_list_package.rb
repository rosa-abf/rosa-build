class AbbSha1ToBuildListPackage < ActiveRecord::Migration
  def change
    add_column :build_list_packages, :sha1, :string
  end
end
