class DeleteDublicateSubscribes < ActiveRecord::Migration
  def up
    execute <<-SQL
      DELETE FROM subscribes s
      WHERE s.id NOT IN (SELECT MIN(s1.id) FROM SUBSCRIBES s1
                                      GROUP BY s1.subscribeable_type, s1.user_id, s1.status, s1.subscribeable_id)
    SQL
  end

  def down
  end
end
