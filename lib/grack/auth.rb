module Grack
  class Auth < Base
    def initialize(app)
      @app = app
    end

    # TODO tests!!!
    def call(env)
      super
      if git?
        return render_not_found if project.blank?

        return ::Rack::Auth::Basic.new(@app) do |u, p|
          user = User.find_for_database_authentication(:login => u) and user.valid_password?(p) and
          ability = ::Ability.new(user) and ability.can?(action, project) # project.members.include?(user)
        end.call(env) unless project.public? and read? # need auth
      end
      @app.call(env) # next app in stack
    end
  end
end
