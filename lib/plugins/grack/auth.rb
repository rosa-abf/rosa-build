module Grack
  class Auth < Base
    def initialize(app)
      @app = app
    end

    # TODO tests!!!
    def _call(env)
      super
      if git?
        return render_not_found if project.blank?

        return ::Rack::Auth::Basic.new(@app) do |u, p|
          user                = User.auth_by_token_or_login_pass(u, p) and
          ability             = ProjectPolicy.new(user, project).send("#{action}?") and
          ENV['GL_ID']        = "user-#{user.id}" and
          ENV['GL_REPO_NAME'] = project.path
        end.call(env) unless project.public? && read? # need auth
      end
      @app.call(env) # next app in stack
    end
  end
end
