require 'spec_helper'

describe ApiDefender do
  def get_basic_auth user = @user, by_token = false
    u,pass = if by_token
               [user.authentication_token, '']
             else
               [user.uname, '123456']
             end
    ActionController::HttpAuthentication::Basic.encode_credentials u, pass
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
      get "/api/v1/users/#{@user.id}.json"
      response.headers['X-RateLimit-Limit'].should == @rate_limit.to_s
    end

    it "should return the correct limit usage for anonymous user" do
      get "/api/v1/users/#{@user.id}.json"
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should return the correct limit usage for anonymous user after authenticated access" do
      get("/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth})
      get "/api/v1/users/#{@user.id}.json"
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-2).to_s
    end

    it "should forbidden anonymous user after exceeding limit rate" do
      (@rate_limit+1).times {get "/api/v1/users/#{@user.id}.json"}
      response.status.should == 403
    end
  end

  context 'for user' do
    it "should return the correct limit usage for auth user" do
      get("/api/v1/users/#{@user.id}.json", {'HTTP_AUTHORIZATION' => get_basic_auth})
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should return the correct limit usage for auth user after anonymous access" do
      get "/api/v1/users/#{@user.id}.json"
      get("/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth})
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should forbidden user after exceeding limit rate" do
      (@rate_limit+1).times {get "/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth}}
      response.status.should == 403
    end

    it "should not forbidden user after exceeding limit rate of the anonymous" do
      (@rate_limit+1).times {get "/api/v1/users/#{@user.id}.json"}
      get("/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth})
      response.status.should == 200
    end
  end

  context 'for system user' do
    it "should not return the limit usage for system user" do
      get("/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth(@system_user, true)})
      response.headers['X-RateLimit-Limit'].should_not == @rate_limit.to_s
    end

    it "should not forbidden system user" do
      (@rate_limit+1).times do
        get "/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth(@system_user, true)}
      end
      response.status.should == 200
    end
  end
end
