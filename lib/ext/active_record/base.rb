class ActiveRecord::Base

  def add_role_to model, role
    return false unless ActiveRecord::Base.relation_acter? model and ActiveRecord::Base.relation_target? self.class
    return false unless ['', model.class.to_s].include? role.to
    rel = Relation.by_object(model).by_target(self).first
    rel = Relation.new(:object_id => model.id, :object_type => model.class.to_s,
                       :target_id => self.id,  :target_type => self.class.to_s) if rel.nil?
    rel.roles << role unless rel.roles.include? role
    rel.save
  end

  def add_role_on model, role
    return false unless ActiveRecord::Base.relation_target? model and ActiveRecord::Base.relation_acter? self.class
    return false unless ['', self.class.to_s].include? role.to
    rel = Relation.by_object(self).by_target(model).first
    rel = Relation.new(:object_id => self.id,  :object_type => self.class.to_s,
                       :target_id => model.id, :target_type => model.class.to_s) if rel.nil?
    rel.roles << role unless rel.roles.include? role
    rel.save
  end

  def roles_to object
    return [] unless ActiveRecord::Base.relation_acter? self.class
    object = object.downcase.to_sym if object.is_a? String
    possible = [self]
    @@relationable[self.class.to_s][:inherits].each do |n|
      possible.concat method(n).call
    end
    possible.flatten
    if object.is_a? Symbol and object == :system
      return possible.map{|obj| obj.global_role}.uniq
    else
      r = possible.inject([]) do |arr, mod|
        rels = Relation.by_object(mod).by_target(object)
        arr.concat rel.map{|rel| rel.roles} if rels.size > 0
        arr << mod.global_role
        arr
      end
      return r.flatten.uniq
    end
  end

  def can_perform? controller, action, target = :system
    all_rights = rights_to target
    needed_right = right_to controller, action
    return all_rights.include? needed_right
  end

  def right_to controller, action
    Right.where(:controller => controller, :action => action).first
  end

  def rights_to object
    r = roles_to(object).compact.uniq
    return [] if r.nil?
    r.map {|role| role.rights}.flatten.compact.uniq
  end

  class << self

    def visible_to object
      return all unless public_instance_methods.include? 'visibility'
      rs = object.roles_to :system
      vis = rs.inject({}) do |h, r|
        h.merge!(r.can_see) {|k, old, new| old.concat(new).uniq}
        h
      end
      vis = vis[self.name]
      return [] if !vis or vis.empty?
      if vis == self::VISIBILITIES
        return all
      else
        return by_visibilities(vis)
      end
    end

    def inherit_rights_from arg
      if relation_acters.include? self
        @@relationable[self.name] ||= {}
        @@relationable[self.name][:inherits] ||= []

        if arg.is_a? Array
          @@relationable[self.name][:inherits].concat(arg)
        else
          @@relationable[self.name][:inherits] << arg
        end
      end
    end

    def relationable?
      return true if @@relationable[self.name] and @@relationable[self.name].size > 0
      false
    end

    def relation_acter? model
      relation_acters.include? model
    end

    def relation_target? model
      relation_targets.include? model
    end

    def relation_acters
      load_all unless @@all_models_loaded
      return Hash[@@relationable.select {|(k,v)| v[:as].include? :object}].keys.map{|m| m.constantize}
    end

    def relation_targets
      load_all unless @@all_models_loaded
      return Hash[@@relationable.select {|(k,v)| v[:as].include? :target}].keys.map{|m| m.constantize}
    end

    def load_all
      Dir["app/models/**/*.rb"].each do |fn|
        require File.expand_path(fn)
      end
      @@all_modles_loaded = true
    end

    protected

      @@relationable = {}
      @@all_models_loaded = false

      def relationable(arg)
        @@relationable[self.name] ||= {}
        @@relationable[self.name][:as] ||= []

        if arg[:as] and [:object, :target].include? arg[:as]
          @@relationable[self.name][:as] << arg[:as]
        else
          @@relationable[self.name][:as] << :target
        end
        @@relationable[self.name][:as].uniq!
      end
  end

end
