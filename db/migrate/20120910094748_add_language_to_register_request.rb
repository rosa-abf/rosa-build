class AddLanguageToRegisterRequest < ActiveRecord::Migration[8.1]
  def change
    add_column :register_requests, :language, :string
  end
end
