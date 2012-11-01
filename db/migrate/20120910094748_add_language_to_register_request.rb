class AddLanguageToRegisterRequest < ActiveRecord::Migration
  def change
    add_column :register_requests, :language, :string
  end
end
