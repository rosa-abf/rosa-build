class Collaborator
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  extend  ActiveModel::Naming

  attr_accessor :role, :actor, :project, :relation
  attr_reader :id, :actor_id, :actor_type, :actor_name, :project_id

  delegate :new_record?, to: :relation

  class << self
    def find_by_project(project)
      res = []
      project.relations.each do |r|
        res << from_relation(r) unless project.owner_id == r.actor_id and project.owner_type == r.actor_type
      end
      return res
    end

    def find(id)
      return self.from_relation(Relation.find(id)) || nil
    end

    def create(args)
      c = self.new(args)
      return c.save ? c : false
    end

    def create!(args)
      c = self.new(args)
      c.save!
      return c
    end
  end

  def initialize(args = {})
    return false if args.blank?
    args.to_options!
    acc_options = args.select{ |(k, v)| k.in? [:actor, :project, :relation] }
    acc_options.each_pair do |name, value|
      send("#{name}=", value)
    end

    if args[:project_id].present?
      @project = Project.find(args[:project_id])
    end
    if args[:actor_id].present? and args[:actor_type].present?
      @actor = args[:actor_type].classify.constantize.find(args[:actor_id])
    end

    relation.role = args[:role] if args[:role].present? #if @relation.present? and args[:role].present?
  end

  def update_attributes(attributes, options = {})
    attributes.each_pair do |k, v|
      send("#{k}=", v)
    end
    save
  end

  def relation=(model)
    @relation = model
    @actor = @relation.actor
    @project = @relation.target
  end

  def id
    relation.try(:id)
  end

  def actor_id
    @actor.try(:id)
  end

  def actor_type
    @actor.class.to_s.underscore
  end

  def actor_name
    if @actor.present?
      @actor.instance_of?(User) ? "#{@actor.uname}#{ @actor.try(:name) and !@actor.name.empty? ? " (#{@actor.name})" : ''}" : @actor.uname
    else
      nil
    end
  end

  def actor_uname
    @actor.uname
  end

  def project_id
    @project.try(:id)
  end

  def role
    relation.try(:role)
  end

  def role=(arg)
    relation.role = arg
  end

  def save
    relation.try(:save)
  end

  def save!
    relation.try(:save!)
  end

  def destroy
    relation.try(:destroy)
    @actor.check_assigned_issues @project
  end

  def attributes
    %w{ id actor_id actor_type actor_name project_id role}.inject({}) do |h, e|
      h.merge(e => send(e))
    end
  end

  def persisted?
    false
  end

  protected

  class << self

    def from_relation(relation)
      return nil unless relation.present?
      return self.new(relation: relation)
    end

  end

  def relation
    return @relation if @relation.present? and @relation.actor == @actor and @relation.target == @project

    if @actor.present? and @project.present?
      @relation = Relation.by_actor(@actor).by_target(@project).limit(1).first
      @relation ||= Relation.new(:actor_id  => @actor.id,   :actor_type  => @actor.class.to_s,
                                 target_id: @project.id, target_type: 'Project')
    else
      @relation = Relation.new
      @relation.actor = @actor
      @relation.target = @project
    end
    @relation
  end

end
Collaborator.include_root_in_json = false
