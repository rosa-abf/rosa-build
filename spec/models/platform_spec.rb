require 'spec_helper'

describe Platform do
  before(:each) do
    Platform.delete_all
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end

  context 'released' do
    it 'should add suffix to name when released' do
      @platform = Factory(:platform)
      old_name = @platform.name

      @platform.released = true
      @platform.save

      @platform.name.should == "#{old_name} #{I18n.t("layout.platforms.released_suffix")}"
    end

    it 'should not add suffix to name when not released' do
      @platform = Factory(:platform, :name => 'name')
      @platform.name.should == 'name'
    end
  end
end
