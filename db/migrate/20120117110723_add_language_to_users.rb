class AddLanguageToUsers < ActiveRecord::Migration[8.1]
  def self.up
    add_column :users, :language, :string, default: 'en'
  end

  def self.down
    remove_column :users, :language
  end
end
