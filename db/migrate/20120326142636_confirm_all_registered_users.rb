class ConfirmAllRegisteredUsers < ActiveRecord::Migration[8.1]
  def up
    User.all.each { |user| user.confirm! }
  end

  def down
  end
end
