require 'spec_helper'

describe ApiDefender do
  def get_basic_auth user = @user, by_token = false
    u,pass = if by_token
               [user.authenticate_token, '']
             else
               [user.uname, '123456']
             end
    ActionController::HttpAuthentication::Basic.encode_credentials u, pass
  end

  before do
    stub_symlink_methods && stub_redis
    @redis = Redis.new
    @password = '123456'

    ApiDefender.class_eval { def cache; Redis.new; end }
  end

  before(:each) do
    keys = @redis.keys.select {|k| k =~ /\Athrottle:/}
    @redis.del(keys) if keys.present?

    @user = FactoryGirl.create :user, :password => @password
    @system_user = FactoryGirl.create :user, :uname => 'rosa_system'
  end

  it "should return the total limit" do
    get "/api/v1/users/#{@user.id}.json"
    response.headers['X-RateLimit-Limit'].should == '500'

  end

  it "should return the correct limit usage" do
    get "/api/v1/users/#{@user.id}.json"
    response.headers['X-RateLimit-Remaining'].should == '499'
  end

  it "should return the correct limit usage for auth user" do
   # get "/api/v1/users/#{@user.id}.json"
    get("/api/v1/users/#{@user.id}.json", {'HTTP_AUTHORIZATION' => get_basic_auth})
    response.headers['X-RateLimit-Remaining'].should == '499'
  end

  it "should return the correct limit usage for auth user after anonymous access" do
    get "/api/v1/users/#{@user.id}.json"
    get("/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth})
    response.headers['X-RateLimit-Remaining'].should == '499'
  end

  it "should return the correct limit usage for anonymous user after authenticated access" do
    get("/api/v1/users/#{@user.id}.json", {}, {'HTTP_AUTHORIZATION' => get_basic_auth})
    get "/api/v1/users/#{@user.id}.json"
    response.headers['X-RateLimit-Remaining'].should == '498'
  end
end
