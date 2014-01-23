class ChangeSubscribeableIdToDecimal < ActiveRecord::Migration
  def up
    add_column :subscribes, :subscribeable_id_tmp, :decimal, precision: 50, scale: 0
    Subscribe.reset_column_information
    Subscribe.all.each {|c| c.update_column :subscribeable_id_tmp, (c.subscribeable_type == 'Grit::Commit' ? c.subscribeable_id.hex : c.subscribeable_id.to_i)}
    remove_column :subscribes, :subscribeable_id
    rename_column :subscribes, :subscribeable_id_tmp, :subscribeable_id
  end

  def down
    add_column :subscribes, :subscribeable_id_tmp, :string
    Subscribe.reset_column_information
    Subscribe.all.each {|c| c.update_column :subscribeable_id_tmp, (c.subscribeable_type == 'Grit::Commit' ? c.subscribeable_id.to_s(16) : c.subscribeable_id.to_s)}
    remove_column :subscribes, :subscribeable_id
    rename_column :subscribes, :subscribeable_id_tmp, :subscribeable_id
  end
end
