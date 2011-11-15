module Grack
  class Auth < Base
    def initialize(app)
      @app = app
    end

    def call(env)      
      if git?(env)
        uname, unixname = env['PATH_INFO'].split('/')[1,2]
        unixname.gsub! /\.git$/, ''
        owner = User.find_by_uname(uname) || Group.find_by_uname(uname)
        project = Project.where(:owner_id => owner.id, :owner_type => owner.class).find_by_unixname(unixname)
        return [404, {}, []] if project.blank?

        # TODO r/rw ?
        unless project.public? # need auth
          ::Rack::Auth::Basic.new(@app) do |user, password|
            user = User.find_for_database_authentication(:login => user) and user.valid_password?(password) and
            users = project.collaborators << project.groups.map(&:members).flatten and users.include?(user) # TODO ACL ?
            # env['REQUEST_METHOD'] == 'GET' # read
            # env['REQUEST_METHOD'] == 'POST' # write
          end.call(env)
        else
          @app.call(env)
        end
      else
        @app.call(env)
      end
    end
  end
end
