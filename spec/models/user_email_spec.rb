require 'spec_helper'

describe UserEmail do
  context 'for simple user' do
    before(:each) do
      @user = Factory(:user)
      #@ability = Ability.new(@stranger)
      @create_params = {:email => 'test@test.com'}
    end

    it 'should not create duplicate email' do
      @stranger = Factory(:user)
      @stranger.emails.create(:email => @user.emails.first.email)
      @stranger.emails.exists?(:email => @user.emails.first.email).should be_false
    end
  end
end
