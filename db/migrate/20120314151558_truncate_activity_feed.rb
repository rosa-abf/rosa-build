# -*- encoding : utf-8 -*-
class TruncateActivityFeed < ActiveRecord::Migration
  def up
    ActivityFeed.destroy_all
  end

  def down
  end
end
