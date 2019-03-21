class AddFailReasonAndHostnameToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :hostname, :string
    add_column :build_lists, :fail_reason, :string
  end
end
