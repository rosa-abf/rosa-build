require 'spec_helper'

describe Group do
  before(:each) do
    stub_symlink_methods
    @group = FactoryGirl.create(:group)
  end

  context 'with mass assignment' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @another_user = FactoryGirl.create(:user)
    end

    it 'should not be able to update uname' do
      @group.should_not allow_mass_assignment_of uname: 'new_uname'
    end

    it 'should not be able to update owner' do
      @group.should_not allow_mass_assignment_of owner_type: 'User', owner_id: @another_user.id
    end
  end

  it 'uname validation' do
    g = FactoryGirl.build(:group, uname: "How do you do...\nmy_group")
    expect(g.valid?).to be_falsy
  end
end
