module WebHooks

  class << self
    protected

    def add_hook(name)
      NAMES << name.to_s
      @schema = []
      yield if block_given?
      SCHEMA[name] = @schema
      @schema = []
    end

    def add_to_schema(type, attrs)
      attrs.each do |attr|
        @schema << [type, attr.to_sym]
      end
    end

    def boolean(*attrs)
      add_to_schema :boolean, attrs
    end

    def string(*attrs)
      add_to_schema :string, attrs
    end

    def password(*attrs)
      add_to_schema :password, attrs
    end
  end

  NAMES = []
  SCHEMA = {}
  add_hook :web do
    string :url
  end
  # temporarily disabled
  # add_hook :hipchat do
  #   string :auth_token, :room, :restrict_to_branch
  #   boolean :notify
  # end
  add_hook :irc do
    string   :server, :port, :room, :nick, :branch_regexes
    password :password
    boolean  :ssl, :message_without_join, :no_colors, :long_url, :notice
  end

  add_hook :jabber do
    string :user
  end

  SCHEMA.freeze
  NAMES.freeze
end
