require 'spec_helper'

describe ApiDefender do
  def get_basic_auth user = @user, by_token = false, by_email = false
    u,pass = if by_token
               [user.authentication_token, '']
             elsif by_email
               [user.email, @password]
             else
               [user.uname, @password]
             end
    ActionController::HttpAuthentication::Basic.encode_credentials u, pass
  end

  def get_request auth_user = nil, by_token = false, by_email = false
    auth = auth_user ? {'HTTP_AUTHORIZATION' => get_basic_auth(auth_user, by_token, by_email)} : {}
    get "/api/v1/users/#{@user.id}.json", {}, auth
  end

  before do
    stub_symlink_methods && stub_redis
    @redis = Redis.new
    @password = '123456'
    @rate_limit = 3 # dont forget change in max_per_window

    ApiDefender.class_eval("def cache; Redis.new; end; def max_per_window; return #{@rate_limit}; end;")
  end

  before(:each) do
    keys = @redis.keys.select {|k| k =~ /\Athrottle:/}
    @redis.del(keys) if keys.present?

    @user = FactoryGirl.create :user, :password => @password
    @system_user = FactoryGirl.create :user, :uname => 'rosa_system'
  end

  context 'for anonymous user' do
    it "should return the total limit" do
      get_request
      response.headers['X-RateLimit-Limit'].should == @rate_limit.to_s
    end

    it "should return the correct limit usage for anonymous user" do
      get_request
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should return the correct limit usage for anonymous user after authenticated access" do
      get_request @user
      get_request
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-2).to_s
    end

    it "should forbidden anonymous user after exceeding limit rate" do
      (@rate_limit+1).times {get_request}
      response.status.should == 403
    end
  end

  context 'for user' do
    it "should return the correct limit usage for auth user" do
      get_request @user
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should allow auth by uname and password" do
      (@rate_limit+1).times {get_request}
      get_request @user
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should allow auth by email and password" do
      (@rate_limit+1).times {get_request}
      get_request @user, false, true
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should allow auth by token" do
      (@rate_limit+1).times {get_request}
      get_request @user, true
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should return the correct limit usage for auth user after anonymous access" do
      get_request
      get_request @user
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should forbidden user after exceeding limit rate" do
      (@rate_limit+1).times {get_request @user}
      response.status.should == 403
    end

    it "should not forbidden user after exceeding limit rate of the anonymous" do
      (@rate_limit+1).times {get_request}
      get_request @user
      response.status.should == 200
    end
  end

  context 'for system user' do
    it "should not return the limit usage for system user" do
      get_request @system_user, true
      response.headers['X-RateLimit-Limit'].should_not == @rate_limit.to_s
    end

    it "should not forbidden system user" do
      (@rate_limit+1).times {get_request @system_user, true}
      response.status.should == 200
    end
  end
end
