module Grack
  class Base # abstract
    def call(env)
      dup._call(env)
    end

    protected

    def _call(env)
      @env = env
      @project = nil
    end

    def git?
      @env['HTTP_USER_AGENT'] =~ /^git\//
    end

    def read?
      (get? && !(@env['REQUEST_URI'] =~ /git-receive-pack$/)) ||
      (post? && !(@env['REQUEST_URI'] =~ /git-upload-pack$/).nil?)
    end

    def write?
      !read?
    end

    def get?
      @env['REQUEST_METHOD'] == 'GET'
    end

    def post?
      @env['REQUEST_METHOD'] == 'POST'
    end

    def action
      write? ? :write : :read
    end

    def project
      @project ||= begin
        uname, name = @env['PATH_INFO'].split('/')[1,2]
        name.gsub!(/\.git$/, '')
        Project.find_by_owner_and_name uname, name
      end
    end

    PLAIN_TYPE = {"Content-Type" => "text/plain"}

    def render_not_found
      [404, PLAIN_TYPE, ["Not Found"]]
    end

    def render_no_access
      [403, PLAIN_TYPE, ["Forbidden"]]
    end
  end
end

# ({"HTTP_ACCEPT"=>"*/*", "HTTP_HOST"=>"localhost:3000", "SERVER_NAME"=>"localhost", "rack.url_scheme"=>"http", "PASSENGER_CONNECT_PASSWORD"=>"xbRC6murG5bIDTsaed8ksaZhjf8yFsadlX4QL0qWNbS", "HTTP_USER_AGENT"=>"git/1.7.7.2", "PASSENGER_SPAWN_METHOD"=>"smart-lv2", "PASSENGER_FRIENDLY_ERROR_PAGES"=>"true", "CONTENT_LENGTH"=>"0", "rack.errors"=>#<IO:0x108494a90>, "SERVER_PROTOCOL"=>"HTTP/1.1", "action_dispatch.secret_token"=>"df2fb72d477491cf15ef0f93449bcb59c3412c255c2386e07772935565c1b6ad23539ed804b8f12e3221e47abb78f5b679693c391acb33477be0e633e7a2e2a4", "rack.run_once"=>false, "rack.version"=>[1, 0], "REMOTE_ADDR"=>"127.0.0.1", "SERVER_SOFTWARE"=>"nginx/1.0.6", "PASSENGER_MIN_INSTANCES"=>"1", "PATH_INFO"=>"/codefoundry.git/info/refs", "SERVER_ADDR"=>"127.0.0.1", "SCRIPT_NAME"=>"", "action_dispatch.parameter_filter"=>[:password], "action_dispatch.show_exceptions"=>true, "rack.multithread"=>false, "PASSENGER_USER"=>"", "PASSENGER_ENVIRONMENT"=>"development", "PASSENGER_SHOW_VERSION_IN_HEADER"=>"true", "rack.multiprocess"=>true, "REMOTE_PORT"=>"49387", "REQUEST_URI"=>"/codefoundry.git/info/refs", "SERVER_PORT"=>"3000", "SCGI"=>"1", "PASSENGER_APP_TYPE"=>"rack", "PASSENGER_USE_GLOBAL_QUEUE"=>"true", "REQUEST_METHOD"=>"GET", "PASSENGER_GROUP"=>"", "PASSENGER_DEBUGGER"=>"false", "DOCUMENT_ROOT"=>"/Users/pasha/Sites/rosa-build/public", "_"=>"_", "PASSENGER_FRAMEWORK_SPAWNER_IDLE_TIME"=>"-1", "UNION_STATION_SUPPORT"=>"false", "rack.input"=>#<PhusionPassenger::Utils::RewindableInput:0x10bb55a20 @rewindable_io=nil, @io=#<PhusionPassenger::Utils::UnseekableSocket:0x10bb56c90 @socket=#<UNIXSocket:0x10bb56b28>>, @unlinked=false>, "HTTP_PRAGMA"=>"no-cache", "QUERY_STRING"=>"", "PASSENGER_APP_SPAWNER_IDLE_TIME"=>"-1"}) (process 41940, thread #<Thread:0x1084a1268>)
# {"rack.session"=>{}, "HTTP_ACCEPT"=>"*/*", "HTTP_HOST"=>"localhost:3000", "SERVER_NAME"=>"localhost", "action_dispatch.remote_ip"=>#<ActionDispatch::RemoteIp::RemoteIpGetter:0x10b621338 @check_ip_spoofing=true, @env={...}, @trusted_proxies=/(^127\.0\.0\.1$|^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\.)/i>, "rack.url_scheme"=>"http", "PASSENGER_CONNECT_PASSWORD"=>"dljpLA91qGH4v2gwaccoAxFysOmSkEFbRtPyPOe9953", "HTTP_USER_AGENT"=>"git/1.7.7.2", "PASSENGER_SPAWN_METHOD"=>"smart-lv2", "PASSENGER_FRIENDLY_ERROR_PAGES"=>"true", "CONTENT_LENGTH"=>"0", "action_dispatch.request.unsigned_session_cookie"=>{}, "rack.errors"=>#<IO:0x10724baa0>, "SERVER_PROTOCOL"=>"HTTP/1.1", "action_dispatch.secret_token"=>"df2fb72d477491cf15ef0f93449bcb59c3412c255c2386e07772935565c1b6ad23539ed804b8f12e3221e47abb78f5b679693c391acb33477be0e633e7a2e2a4", "rack.run_once"=>false, "rack.version"=>[1, 0], "REMOTE_ADDR"=>"127.0.0.1", "SERVER_SOFTWARE"=>"nginx/1.0.6", "PASSENGER_MIN_INSTANCES"=>"1", "PATH_INFO"=>"/pasha/mc.git/info/refs", "SERVER_ADDR"=>"127.0.0.1", "SCRIPT_NAME"=>"", "action_dispatch.parameter_filter"=>[:password], "action_dispatch.show_exceptions"=>true, "rack.multithread"=>false, "PASSENGER_USER"=>"", "PASSENGER_ENVIRONMENT"=>"development", "PASSENGER_SHOW_VERSION_IN_HEADER"=>"true", "action_dispatch.cookies"=>{}, "rack.multiprocess"=>true, "REMOTE_PORT"=>"49643", "REQUEST_URI"=>"/pasha/mc.git/info/refs", "SERVER_PORT"=>"3000", "SCGI"=>"1", "PASSENGER_APP_TYPE"=>"rack", "PASSENGER_USE_GLOBAL_QUEUE"=>"true", "rack.session.options"=>{:httponly=>true, :expire_after=>nil, :domain=>nil, :path=>"/", :secure=>false, :id=>nil}, "REQUEST_METHOD"=>"GET", "PASSENGER_GROUP"=>"", "PASSENGER_DEBUGGER"=>"false", "DOCUMENT_ROOT"=>"/Users/pasha/Sites/rosa-build/public", "warden"=>Warden::Proxy:2242130160 @config={:failure_app=>Devise::FailureApp, :default_scope=>:user, :intercept_401=>false, :scope_defaults=>{}, :default_strategies=>{:user=>[:rememberable, :database_authenticatable]}}, "_"=>"_", "PASSENGER_FRAMEWORK_SPAWNER_IDLE_TIME"=>"-1", "UNION_STATION_SUPPORT"=>"false", "rack.input"=>#<PhusionPassenger::Utils::RewindableInput:0x10b6225f8 @rewindable_io=nil, @io=#<PhusionPassenger::Utils::UnseekableSocket:0x10a8f5a10 @socket=#<UNIXSocket:0x10b623700>>, @unlinked=false>, "HTTP_PRAGMA"=>"no-cache", "QUERY_STRING"=>"", "PASSENGER_APP_SPAWNER_IDLE_TIME"=>"-1"}
