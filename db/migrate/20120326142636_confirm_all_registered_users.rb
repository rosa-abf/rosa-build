class ConfirmAllRegisteredUsers < ActiveRecord::Migration
  def up
    User.all.each { |user| user.confirm! }
  end

  def down
  end
end
