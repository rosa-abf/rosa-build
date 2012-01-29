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

    it 'should not create duplicate lowercase emails' do
      @stranger = Factory(:user)
      @stranger.emails.create(:email => @user.email.upcase)
      @stranger.emails.exists?(:email => @user.email.upcase).should be_false
    end

    it 'should not create too many emails' do
      15.times {|i| @user.emails.create(:email => Factory.next(:email))}
      @user.emails.count.should be_equal(UserEmail::MAX_EMAILS)
    end
  end
end
