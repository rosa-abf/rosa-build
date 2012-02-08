# -*- encoding : utf-8 -*-
class Git::Repository
  delegate :commits, :commit, :tree, :tags, :heads, :commit_count, :log, :branches, :to => :repo

  attr_accessor :path, :name, :repo, :last_actor

  def initialize(path)
    @path = path
    @update_callbacks = []
  end

  def master
    commits('master', 1).first
  end

  def to_s
    name
  end

  def repo
    @repo ||= Grit::Repo.new(path)
  end

  def after_update_file(&block)
    @update_callbacks << block
  end

  def update_file(path, data, options = {})
    ref = options[:ref].to_s || 'master'
    actor = get_actor(options[:actor])
    message = options[:message] || "Updated file #{File.split(path).last}"

    # can not write to unexisted branch
    return false if branches.select{|b| b.name == ref}.size != 1

    parent = commits(ref).first

    index = repo.index
    index.read_tree(parent.tree.id)

    index.add(path, data)
    sha = index.commit(message, :parents => [parent], :actor => actor, :last_tree => parent.tree.id, :head => ref)
    @update_callbacks.each do |cb|
      cb.call(self, sha1)
    end
    sha
  end

  def self.create(path)
    repo = Grit::Repo.init_bare(path)
    repo.enable_daemon_serve
  end

  def paginate_commits(treeish, options = {})
    options[:page] = 1 unless options[:page].present?
    options[:page] = options[:page].to_i

    options[:per_page] = 20 unless options[:per_page].present?
    options[:per_page] = options[:per_page].to_i

    skip = options[:per_page] * (options[:page] - 1)
    last_page = (skip + options[:per_page]) >= commit_count(treeish)

    [commits(treeish, options[:per_page], skip), options[:page], last_page]
  end

  # Pretty object inspection
  def inspect
    %Q{#<Git::Repository "#{@path}">}
  end

  protected

    def get_actor(actor = nil)
      @last_actor = case actor.class.to_s
        when 'Grit::Actor' then options[:actor]
        when 'Hash'        then Grit::Actor.new(actor[:name], actor[:email])
        when 'String'      then Grit::Actor.from_stirng(actor)
        else begin
          if actor.respond_to?(:name) and actor.respond_to?(:email)
            Grit::Actor.new(actor.name, actor.email)
          else
            config = Grit::Config.new(repo)
            Grit::Actor.new(config['user.name'], config['user.email'])
          end
        end
      end
      @last_actor
    end

end
