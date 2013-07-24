class CreatePlatformArchSettings < ActiveRecord::Migration

  def up
    create_table :platform_arch_settings do |t|
      t.integer   :platform_id, :null => false
      t.integer   :arch_id,     :null => false
      t.integer 	:time_living, :null => false
      t.boolean   :default
      t.timestamps
    end
    add_index :platform_arch_settings, [:platform_id, :arch_id], :unique => true

    arch_ids = Arch.where(:name => %w(i586 x86_64)).pluck(:id)
    Platform.main.each do |platform|
      arch_ids.each do |arch_id|
        platform.platform_arch_settings.create(
          :arch_id      => arch_id,
          :default      => true,
          :time_living  => PlatformArchSetting::DEFAULT_TIME_LIVING / 60
        )
      end
    end

  end

  def down
    remove_index  :platform_arch_settings, :column => [:platform_id, :arch_id]
    drop_table    :platform_arch_settings
  end
end
