class AddFailReasonAndHostnameToBuildLists < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :hostname, :string
    add_column :build_lists, :fail_reason, :string
  end
end
