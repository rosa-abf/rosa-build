require 'spec_helper'

describe ApiDefender, type: :request do
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

  def get_request2 auth_user = nil, by_token = false, by_email = false
    auth_user = FactoryGirl.create(:user) if !auth_user && APP_CONFIG['anonymous_access'] == false
    get_request auth_user, by_token, by_email
  end

  before do
    stub_symlink_methods
    @redis = Redis.new
    @password = '123456'
    @rate_limit = 3 # dont forget change in max_per_window

    ApiDefender.class_eval("def cache; Redis.new; end; def max_per_window; return #{@rate_limit}; end;")
  end

  before(:each) do
    @user = FactoryGirl.create :user, password: @password
    @system_user = FactoryGirl.create :user, role: 'system'
  end

  if APP_CONFIG['anonymous_access'] == true
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
  else
    it "should forbidden anonymous access" do
      get_request
      response.status.should == 401
    end
  end

  context 'for user' do
    it "should return the correct limit usage for auth user" do
      get_request @user
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should allow auth by uname and password" do
      (@rate_limit+1).times {get_request2}
      get_request @user
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should allow auth by email and password" do
      (@rate_limit+1).times {get_request2}
      get_request @user, false, true
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should allow auth by token" do
      (@rate_limit+1).times {get_request2}
      get_request @user, true
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should return the correct limit usage for auth user after other user" do
      get_request2
      get_request @user
      response.headers['X-RateLimit-Remaining'].should == (@rate_limit-1).to_s
    end

    it "should forbidden user after exceeding limit rate" do
      (@rate_limit+1).times {get_request @user}
      response.status.should == 403
    end

    it "should not forbidden user after exceeding limit rate of the other user" do
      (@rate_limit+1).times {get_request2}
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

  context 'for allowed addresses' do
    let(:remote_addr) { APP_CONFIG['allowed_addresses'].first }
    it 'should not return the limit usage for allowed address' do
      get "/api/v1/users/#{@user.id}.json", {}, {'REMOTE_ADDR' =>  remote_addr }
      response.headers['X-RateLimit-Limit'].should_not == @rate_limit.to_s
    end

    it 'should not forbidden allowed address' do
      (@rate_limit+1).times { get "/api/v1/users/#{@user.id}.json", {}, {'REMOTE_ADDR' =>  remote_addr } }
      response.status.should == 200
    end
  end

end
