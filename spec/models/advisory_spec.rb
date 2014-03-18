require 'spec_helper'

shared_examples_for 'attach advisory to build_list' do

  it 'ensure that advisory has been attached to build_list' do
    build_list.reload.advisory.should == advisory
  end

  it 'ensure that save_to_platform of build_list has been attached to advisory' do
    build_list.save_to_platform.advisories.should include(advisory)
  end

  it 'ensure that projects of build_list has been attached to advisory' do
    build_list.project.advisories.should include(advisory)
  end

end

describe Advisory do
  before { stub_symlink_methods; stub_redis }
  context 'attach_build_list' do
    let(:build_list) { FactoryGirl.create(:build_list) }

    context 'attach new advisory to build_list' do
      let(:advisory) { FactoryGirl.build(:advisory) }
      before do
        advisory.attach_build_list(build_list)
      end

      it_should_behave_like 'attach advisory to build_list'

      it 'ensure that advisory has been created' do
        Advisory.should have(1).item
      end
    end

    context 'attach old advisory to build_list' do
      let(:advisory) { FactoryGirl.create(:advisory) }
      before do
        advisory.attach_build_list(build_list)
      end

      it_should_behave_like 'attach advisory to build_list'
    end

  end
end
