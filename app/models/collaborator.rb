# -*- encoding : utf-8 -*-
class Collaborator
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  include ActiveModel::MassAssignmentSecurity

  attr_accessor :role, :actor, :project
  attr_reader :id, :type, :name, :project_id

  attr_accessible :role

  delegate :new_record?, :to => :relation

  class << self
    def find_by_project(project, opts = {})
      (id, type) = if opts[:id].present?
                     if opts[:type].present?
                       [opts[:id], opts[:type]]
                     else
                       opts[:id].split('-', 2)
                     end
                   else
                     [nil, nil]
                   end
      puts id
      puts type
      if id.present? and type.present?
        rel = project.relations.where(:object_id => id, :object_type => type.classify).first
        puts rel.inspect
        res = from_relation(project.relations.where(:object_id => id, :object_type => type.classify).first)
      else
        res = []
        project.relations.each do |r|
          res << from_relation(r) unless project.owner_id == r.object_id and project.owner_type == r.object_type
        end
      end
      return res
    end

    def from_relation(relation)
      return self.new(:relation => relation, :id => relation.object_id,
                      :type => relation.object_type, :project_id => relation.target_id)
    end
  end

  def initialize(args = {})
    args.to_options!
    acc_options = args.select{ |(k, v)| k.in? [:actor, :project] }
    acc_options.each_pair do |name, value|
      send("#{name}=", value)
    end

    if @project.nil? and args[:project_id].present?
      @project = Project.find(args[:project_id])
    end

    if @actor.nil? and args[:type].present? and args[:id].present?
      @actor = args[:type].classify.constantize.find(args[:id].to_s.split('-', 2).first.to_i) rescue nil
    end

    if args[:relation]
      @relation = args[:relation]
    else
      setup_relation
    end

    @relation.role = args[:role] if args[:role]
  end

  def update_attributes(attributes, options = {})
    sanitize_for_mass_assignment(attributes, options[:as]).each_pair do |k, v|
      send("#{k}=", v)
    end
    save
  end

  def actor=(model)
    @actor = model

    setup_relation
  end

  def project=(model)
    @project = model

    setup_relation
  end

  def id
    @actor.try(:id)
  end

  def type
    @actor.class.to_s.underscore
  end

  def name
    if @actor.present?
      @actor.instance_of?(User) ? "#{@actor.uname} (#{@actor.name})" : @actor.uname
    else
      nil
    end
  end

  def project_id
    @project.try(:id)
  end

  def role
    @relation.role
  end

  def role=(arg)
    @relation.role = arg
  end

  def save
    @relation.try(:save)
  end

  def save!
    @relation.try(:save!)
  end

  def destroy
    @relation.try(:destroy)
  end

  def attributes
    %w{ id type name project_id role}.inject({}) do |h, e|
      h.merge(e => send(e))
    end
  end

  def persisted?
    false
  end

  protected

  def relation
    setup_relation
    @relation
  end

  def setup_relation
    if @actor.present? and @project.present?
      @relation = Relation.by_object(@actor).by_target(@project).limit(1).first
      @relation ||= Relation.new(:object_id => @actor.id,   :object_type => @actor.class.to_s.underscore,
                                 :target_id => @project.id, :target_type => 'Project')
    else
      @relation = Relation.new
      @relation.object = @actor
      @relation.target = @project
    end
  end

end
Collaborator.include_root_in_json = false
