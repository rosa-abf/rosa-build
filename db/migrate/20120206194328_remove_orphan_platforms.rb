class RemoveOrphanPlatforms < ActiveRecord::Migration
  def self.up
    Platform.all.each {|x| x.destroy unless x.owner.present?}
  end

  def self.down
  end
end
